# frozen_string_literal: true

require "rack"
require "json"

module Nextrb
  # Response is a wrapper around Rack::Response that makes it easier to generate
  # rich responses easily.
  class Response
    include Common

    attr_reader :req, :resp, :env

    def initialize(env)
      @env = env
      @req = Nextrb::Request.new(env)
      @resp = Rack::Response.new
      content_type(Rack::MediaType.type(env["HTTP_ACCEPT"]))
    end

    # whether or not the status is set to 1xx
    def informational? = status.between?(100, 199)
    # whether or not the status is set to 2xx
    def success? = status.between?(200, 299)
    # whether or not the status is set to 3xx
    def redirect? = status.between?(300, 399)
    # whether or not the status is set to 4xx
    def client_error? = status.between?(400, 499)
    # whether or not the status is set to 5xx
    def server_error? = status.between?(500, 599)
    # whether or not the status is set to 404
    def not_found? = status == 404
    # whether or not the status is set to 400
    def bad_request? = status == 400

    # sugar for `respond(body, :ok)`
    def ok(body) = respond(body, :ok)
    # sugar for `respond(body, :not_found)`
    def not_found(body) = respond(body, :not_found)
    # sugar for `respond(body, :bad_request)`
    def bad_request(body) = respond(body, :bad_request)
    # sugar for `respond(body, :unauthorized)`
    def unauthorized(body) = respond(body, :unauthorized)
    # sugar for `respond(body, :internal_error)`
    def internal_error(body) = respond(body, :internal_server_error)

    # immediately return okay status without running any following middleware.
    def ok!(msg = "") = raise OKAY, msg
    # immediately return not found status without running any following middleware.
    def not_found!(msg = "") = raise NotFound, msg
    # immediately return bad request status without running any following middleware.
    def bad_request!(msg = "") = raise BadRequest, msg
    # immediately return unauthorized status without running any following middleware.
    def unauthorized!(msg = "") = raise Unauthorized, msg
    # immediately return internal error status without running any following middleware.
    def internal_error!(msg = "") = raise InternalError, msg

    # respond with text content
    def text(body, stat = :ok) = answer(stat, :text, body)
    # respond with json content
    def json(body, stat = :ok) = answer(stat, :json, JSON.dump(body))
    # respond with html content
    def html(body, stat = :ok) = answer(stat, :html, body)
    # respond with a rendered component. sugar for `html(view.render)`
    def render(klass, stat = :ok) = html(klass.render, stat)

    # respond will choose what kind of content to respond with depending on what
    # kind of data you give it.
    #
    # `respond({message: "hi"}, :ok)` => application/json JSON response
    # `respond(AppView, :ok)` => text/html HTML Component response
    # `respond("OKAY", :ok)` => text/plain response
    def respond(obj, stat)
      case obj
      when Hash then json(obj, stat)
      when Nextrb::Component then render(obj, stat)
      when String then text(obj, stat)
      else status(stat)
      end
    end

    # set the status, content_type, and body all in one call.
    def answer(stat, contenttype, body_content)
      status(stat)
      content_type(contenttype)
      body(body_content)
    end

    # redirect the request to a uri
    def redirect(uri)
      http_version = env["SERVER_PROTOCOL"]
      if (http_version == "HTTP/1.1") && (env["REQUEST_METHOD"] != "GET")
        status(303)
      else
        status(302)
      end
      headers["Location"] = uri.to_s
    end

    # Sugar for redirect(request.referer)
    def redirect_back = redirect(req.referer)

    def uri(addr = nil, absolute: true)
      port_required = req.forwarded? || (req.port != (req.secure? ? 443 : 80))
      uri = [host = String.new]
      if absolute
        host.concat("http#{"s" if req.secure?}://", port_required ? req.host_with_port : req.host)
      end
      uri << (addr || req.path_info).to_s
      File.join uri
    end

    def headers(hash = nil)
      resp.headers.merge! hash if hash
      resp.headers
    end

    def status(value = nil)
      resp.status = Rack::Utils.status_code(value) if value
      resp.status
    end

    def mime_type(type)
      return type      if type.nil?
      return type.to_s if type.to_s.include?("/")

      type = ".#{type}" unless type.to_s[0] == "."
      Rack::Mime.mime_type(type, nil)
    end

    def content_type(kind = nil)
      headers["Content-Type"] = mime_type(kind) if kind
      headers["Content-Type"]
    end

    def content_length(len = nil)
      headers["Content-Length"] = len.to_s if len
      headers["Content-Length"]
    end

    def body(value = nil)
      resp.body = [value] if value
      resp.body
    end

    # Specify response freshness policy for HTTP caches (Cache-Control header).
    # Any number of non-value directives (:public, :private, :no_cache,
    # :no_store, :must_revalidate, :proxy_revalidate) may be passed along with
    # a Hash of value directives (:max_age, :s_maxage).
    #
    #   cache_control :public, :must_revalidate, :max_age => 60
    #   => Cache-Control: public, must-revalidate, max-age=60
    #
    # See RFC 2616 / 14.9 for more on standard cache control directives:
    # http://tools.ietf.org/html/rfc2616#section-14.9.1
    def cache_control(*values)
      hash = extract_cache_control_hash(values)
      values.map! { |value| value.to_s.tr("_", "-") }
      hash.each { |key, value| values << cache_control_pair(key, value) }

      headers["Cache-Control"] = values.join(", ") if values.any?
    end

    # Set the response entity tag (HTTP 'ETag' header) and halt if conditional
    # GET matches. The +value+ argument is an identifier that uniquely
    # identifies the current version of the resource. The weak argument will allow
    # a weak value but defaults to strong.
    #
    # When the current request includes an 'If-None-Match' header with a
    # matching etag, execution is immediately halted. If the request method is
    # GET or HEAD, a '304 Not Modified' response is sent.
    def etag(value, weak: false, new_resource: req.post?)
      headers["ETag"] = etag_header_value(value, weak)
      return unless success? || status == 304

      raise(req.safe? ? NotModified : PreconditionFailed) if etag_matches?(env["HTTP_IF_NONE_MATCH"], new_resource)
      raise PreconditionFailed if env["HTTP_IF_MATCH"] && !etag_matches?(env["HTTP_IF_MATCH"], new_resource)
    end

    # Set the Expires header and Cache-Control/max-age directive. Amount
    # can be an integer number of seconds in the future or a Time object
    # indicating when the response should be considered "stale". The remaining
    # "values" arguments are passed to the #cache_control helper:
    #
    #   expires 500, :public, :must_revalidate
    #   => Cache-Control: public, must-revalidate, max-age=500
    #   => Expires: Mon, 08 Jun 2009 08:50:17 GMT
    #
    def expires(amount, *values)
      values << {} unless values.last.is_a?(Hash)
      time, max_age = expires_time_and_max_age(amount)

      values.last.merge!(max_age: max_age) { |_key, v1, v2| v1 || v2 }
      cache_control(*values)

      headers["Expires"] = time.httpdate
    end

    # Set the last modified time of the resource (HTTP 'Last-Modified' header)
    # and halt if conditional GET matches. The +time+ argument is a Time,
    # DateTime, or other object that responds to +to_time+.
    #
    # When the current request includes an 'If-Modified-Since' header that is
    # equal or later than the time specified, execution is immediately halted
    # with a '304 Not Modified' response.
    def last_modified(time)
      return unless time

      time = time_for(time)
      headers["Last-Modified"] = time.httpdate
      return if env["HTTP_IF_NONE_MATCH"]

      check_if_modified_since(time)
      check_if_unmodified_since(time)
    end

    MULTIPART_BOUNDARY = "AaB03x"
    MULTIPART_FORM_DATA_REPLACEMENT_TABLE = {
      '"' => "%22",
      "\r" => "%0D",
      "\n" => "%0A"
    }.freeze

    def send_file(req, filename, attachment: false)
      if attachment
        headers["Content-Disposition"] =
          format('attachment; filename="%s"',
                 File.basename(filename).gsub(/["\r\n]/, MULTIPART_FORM_DATA_REPLACEMENT_TABLE))
      end
      serve_file(req, filename)
    end

    def finish
      clear_body_headers if informational? || [204, 304].include?(status)
      resp.body = [] if [204, 304].include?(status)
      content_length(body.map(&:bytesize).reduce(0, :+)) if calculate_content_length?
      resp.to_a
    end

    private

    def etag_matches?(list, new_resource = req.post?)
      return !new_resource if list == "*"

      list.to_s.split(",").map(&:strip).include?(headers["ETag"])
    end

    def etag_header_value(value, weak) = format('%<weak>s"%<value>s"', weak: weak ? "W/" : "", value: value)

    def extract_cache_control_hash(values)
      return {} unless values.last.is_a?(Hash)

      hash = values.pop
      hash.reject! { |_k, v| v == false }
      hash.reject! { |k, v| values << k if v == true }
      hash
    end

    def cache_control_pair(key, value)
      key = key.to_s.tr("_", "-")
      value = value.to_i if %w[max-age s-maxage].include? key
      "#{key}=#{value}"
    end

    def expires_time_and_max_age(amount)
      return [Time.now + amount.to_i, amount] if amount.is_a? Integer

      time = time_for(amount)
      [time, time - Time.now]
    end

    def check_if_modified_since(time)
      return unless (status == 200) && env["HTTP_IF_MODIFIED_SINCE"]

      since = Time.httpdate(env["HTTP_IF_MODIFIED_SINCE"]).to_i
      raise NotModified if since >= time.to_i
    end

    def check_if_unmodified_since(time)
      return unless (success? || (status == 412)) && env["HTTP_IF_UNMODIFIED_SINCE"]

      since = Time.httpdate(env["HTTP_IF_UNMODIFIED_SINCE"]).to_i
      raise PreconditionFailed if since < time.to_i
    end

    def time_for(value)
      if value.is_a? Numeric
        Time.at value
      elsif value.respond_to? :to_s
        Time.parse value.to_s
      else
        value.to_time
      end
    end

    def serve_file(req, filename)
      content_type(File.extname(filename))
      last_modified(File.mtime(filename))
      size = ::File.size?(filename) || ::File.read(filename).bytesize
      ranges = Rack::Utils.get_byte_ranges(req.get_header("HTTP_RANGE"), size)
      if ranges.nil? then send_full_file_content(filename, size)
      elsif ranges.empty? then bad_file_send_range(size)
      else send_partial_file(filename, ranges, size)
      end
    rescue Errno::ENOENT
      raise NotFound
    end

    def send_full_file_content(filename, size)
      content_length(size)
      resp.body = if req.head?
                    []
                  else
                    Rack::Files::Iterator.new(filename, [0..(size - 1)], mime_type: content_type,
                                                                         size: size)
                  end
    end

    def bad_file_send_range(size)
      headers["content-range"] = "bytes */#{size}"
      http_error("Byte range unsatisfiable", 416)
    end

    def http_error(message, code) = answer(code, :text, message)

    def send_partial_file(filename, ranges, size)
      if ranges.size == 1
        headers["content-range"] = "bytes #{ranges[0].begin}-#{ranges[0].end}/#{size}"
      else
        content_type("multipart/byteranges; boundary=#{MULTIPART_BOUNDARY}")
      end
      status(206)
      resp.body = req.head? ? [] : Rack::Files::BaseIterator.new(filename, ranges, mime_type: content_type, size: size)
      content_length(size)
    end

    def clear_body_headers
      headers.delete "content-length"
      headers.delete "content-type"
    end

    def calculate_content_length?
      headers["content-type"] && !headers["content-length"] && body.is_a?(Array)
    end
  end
end
