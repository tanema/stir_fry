# frozen_string_literal: true

require "rack"
require "json"

module Nextrb
  # Response is a wrapper around Rack::Response that makes it easier to generate
  # rich responses easily.
  class Response
    attr_reader :req, :resp, :env

    def initialize(env)
      @env = env
      @req = Rack::Request.new(env)
      @resp = Rack::Response.new
      content_type(Rack::MediaType.type(env["HTTP_ACCEPT"]))
    end

    def informational? = status.between?(100, 199)
    def success? = status.between?(200, 299)
    def redirect? = status.between?(300, 399)
    def client_error? = status.between?(400, 499)
    def server_error? = status.between?(500, 599)
    def not_found? = status == 404
    def bad_request? = status == 400

    def ok(body) = respond(body, :ok)
    def not_found(body) = respond(body, :not_found)
    def bad_request(body) = respond(body, :bad_request)
    def unauthorized(body) = respond(body, :unauthorized)
    def internal_error(body) = respond(body, 500)

    def ok! = raise OKAY
    def not_found! = raise NotFound
    def bad_request! = raise BadRequest
    def unauthorized! = raise Unauthorized
    def internal_error! = raise Error

    def respond(obj, stat)
      case obj
      when Hash then json(body, stat)
      when Nextrb::Component then render(obj, stat)
      when String then text(body, stat)
      else status(stat)
      end
    end

    def text(body, stat = :ok) = answer(stat, :text, body)
    def json(body, stat = :ok) = answer(stat, :json, JSON.dump(body))
    def html(body, stat = :ok) = answer(stat, :html, body)
    def render(klass, stat = :ok) = html(klass.render, stat)

    def answer(stat, kind, content)
      status(stat)
      content_type(kind)
      body(content)
    end

    def redirect(uri)
      http_version = env["SERVER_PROTOCOL"]
      if (http_version == "HTTP/1.1") && (env["REQUEST_METHOD"] != "GET")
        status(303)
      else
        status(302)
      end
      headers["Location"] = uri.to_s
    end

    def redirect_back = redirect(req.referer)

    def uri(addr = nil, absolute: true)
      port_required = req.forwarded? || (req.port != (req.secure? ? 443 : 80))
      uri = [host = String.new]
      if absolute
        host.push("http#{"s" if req.secure?}://", port_required ? req.host_with_port : req.host)
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

    # content_type will set the content-type header on the response if not already set.
    # If a content-type should be forced, meaning set even if it was already set, force
    # should be set to true.
    def content_type(kind = nil)
      headers["Content-Type"] = mime_type(kind) if kind
      headers["Content-Type"]
    end

    def last_modified(mtime = nil)
      headers["Last-Modified"] = mtime if mtime
      headers["Last-Modified"]
    end

    def content_length(len = nil)
      headers["Content-Length"] = len.to_s if len
      headers["Content-Length"]
    end

    def body(value = nil)
      resp.body = [value] if value
      resp.body
    end

    MULTIPART_BOUNDARY = "AaB03x"
    MULTIPART_FORM_DATA_REPLACEMENT_TABLE = {
      '"' => "%22",
      "\r" => "%0D",
      "\n" => "%0A"
    }.freeze

    def send_attachment(req, filename)
      headers["Content-Disposition"] =
        format('attachment; filename="%s"',
               File.basename(filename).gsub(/["\r\n]/, MULTIPART_FORM_DATA_REPLACEMENT_TABLE))
      servce_file(req, filename)
    end

    def send_file(req, filename)
      serve_file(req, filename)
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

    def finish
      clear_body_headers if informational? || [204, 304].include?(status)
      resp.body = [] if [204, 304].include?(status)
      content_length(body.map(&:bytesize).reduce(0, :+)) if calculate_content_length?
      resp.to_a
    end

    private

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
