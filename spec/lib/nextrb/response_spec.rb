# frozen_string_literal: true

require "rack/mock_request"

class ResponseSpecComponent < Nextrb::Component
  template_source "<p>a component</p>"
end

RSpec.describe Nextrb::Response do
  def build_response(path = "/", opts = {})
    described_class.new(Rack::MockRequest.env_for(path, opts))
  end

  describe "#initialize" do
    it "derives the default content type from the accept header" do
      resp = build_response("/", "HTTP_ACCEPT" => "application/json")
      expect(resp.content_type).to eq("application/json")
    end
  end

  describe "status predicates" do
    {
      100 => %i[informational?],
      200 => %i[success?],
      302 => %i[redirect?],
      400 => %i[client_error? bad_request?],
      404 => %i[client_error? not_found?],
      500 => %i[server_error?]
    }.each do |code, truthy_predicates|
      it "reports the right predicates for status #{code}" do
        resp = build_response
        resp.status(code)
        all_predicates = %i[informational? success? redirect? client_error? server_error? not_found? bad_request?]
        all_predicates.each do |predicate|
          expect(resp.public_send(predicate)).to eq(truthy_predicates.include?(predicate))
        end
      end
    end
  end

  describe "#respond (via #ok/#not_found/#bad_request/#unauthorized/#internal_error)" do
    it "json-encodes a Hash" do
      resp = build_response
      resp.ok({ message: "hi" })
      expect(resp.status).to eq(200)
      expect(resp.content_type).to eq("application/json")
      expect(JSON.parse(resp.body.join)).to eq("message" => "hi")
    end

    it "renders a Component as html" do
      resp = build_response
      resp.ok(ResponseSpecComponent.new)
      expect(resp.content_type).to eq("text/html")
      expect(resp.body).to eq(["<p>a component</p>"])
    end

    it "sends a String as plain text" do
      resp = build_response
      resp.not_found("nothing here")
      expect(resp.status).to eq(404)
      expect(resp.content_type).to eq("text/plain")
      expect(resp.body).to eq(["nothing here"])
    end

    it "sets only the status for anything else" do
      resp = build_response
      resp.unauthorized(nil)
      expect(resp.status).to eq(401)
    end

    it "internal_error responds with 500" do
      resp = build_response
      resp.internal_error("boom")
      expect(resp.status).to eq(500)
    end
  end

  describe "bang methods" do
    it "raise their matching Nextrb error with the given message" do
      resp = build_response
      expect { resp.not_found!("gone") }.to raise_error(Nextrb::NotFound, "gone")
      expect { resp.bad_request!("nope") }.to raise_error(Nextrb::BadRequest, "nope")
      expect { resp.unauthorized!("no") }.to raise_error(Nextrb::Unauthorized, "no")
      expect { resp.internal_error!("oops") }.to raise_error(Nextrb::InternalError, "oops")
      expect { resp.ok!("done") }.to raise_error(Nextrb::OKAY, "done")
    end
  end

  describe "#redirect" do
    it "uses 302 for a GET request" do
      resp = build_response("/", method: "GET", "HTTP_VERSION" => "HTTP/1.1")
      resp.redirect("/next")
      expect(resp.status).to eq(302)
      expect(resp.headers["Location"]).to eq("/next")
    end

    it "uses 303 for a non-GET HTTP/1.1 request" do
      resp = build_response("/", method: "POST", "HTTP_VERSION" => "HTTP/1.1")
      resp.redirect("/next")
      expect(resp.status).to eq(303)
    end

    it "redirect_back redirects to the referer" do
      resp = build_response("/", method: "GET", "HTTP_VERSION" => "HTTP/1.1", "HTTP_REFERER" => "/prev")
      resp.redirect_back
      expect(resp.headers["Location"]).to eq("/prev")
    end
  end

  describe "#uri" do
    it "builds an absolute uri to the current path by default" do
      resp = build_response("/a/b")
      expect(resp.uri).to eq("http://example.org/a/b")
    end

    it "builds a relative uri when absolute: false" do
      resp = build_response("/a/b")
      expect(resp.uri(absolute: false)).to eq("/a/b")
    end

    it "uses the given addr instead of the current path" do
      resp = build_response("/a/b")
      expect(resp.uri("/other")).to eq("http://example.org/other")
    end

    it "includes a non-default port" do
      resp = build_response("https://example.com:8443/a/b")
      expect(resp.uri).to eq("https://example.com:8443/a/b")
    end
  end

  describe "headers, status, and content helpers" do
    it "merges extra headers without dropping existing ones" do
      resp = build_response
      resp.headers("X-One" => "1")
      resp.headers("X-Two" => "2")
      expect(resp.headers).to include("X-One" => "1", "X-Two" => "2")
    end

    it "accepts symbol status names and returns the numeric code" do
      resp = build_response
      expect(resp.status(:created)).to eq(201)
      expect(resp.status).to eq(201)
    end

    it "only sets content_type if not already set, unless given a fresh value" do
      resp = build_response
      resp.content_type(:json)
      expect(resp.content_type).to eq("application/json")
      resp.content_type(:html)
      expect(resp.content_type).to eq("text/html")
    end

    it "writes last_modified as an httpdate and reads/writes content_length" do
      resp = build_response
      time = Time.now
      resp.last_modified(time)
      resp.content_length(42)
      expect(resp.headers["Last-Modified"]).to eq(time.httpdate)
      expect(resp.content_length).to eq("42")
    end

    it "reads and writes body" do
      resp = build_response
      resp.body("hello")
      expect(resp.body).to eq(["hello"])
    end
  end

  describe "#cache_control" do
    it "joins flags and key=value pairs, dropping falsy entries and promoting true flags" do
      resp = build_response
      resp.cache_control(:public, :no_cache, max_age: 60, must_revalidate: true, private: false)
      expect(resp.headers["Cache-Control"]).to eq("public, no-cache, must-revalidate, max-age=60")
    end
  end

  describe "#expires" do
    it "sets Expires and a derived max-age Cache-Control from a second count" do
      resp = build_response
      resp.expires(60, :public)
      expect(resp.headers["Cache-Control"]).to eq("public, max-age=60")
      expect(resp.headers["Expires"]).to eq((Time.now + 60).httpdate)
    end
  end

  describe "#etag" do
    it "quotes a strong etag by default and a weak one when requested" do
      resp = build_response
      resp.etag("abc")
      expect(resp.headers["ETag"]).to eq('"abc"')

      resp = build_response
      resp.etag("abc", weak: true)
      expect(resp.headers["ETag"]).to eq('W/"abc"')
    end

    it "raises NotModified for a safe request whose If-None-Match matches" do
      resp = build_response("/", method: "GET", "HTTP_IF_NONE_MATCH" => '"abc"')
      expect { resp.etag("abc") }.to raise_error(Nextrb::NotModified)
    end

    it "raises PreconditionFailed for an unsafe request whose If-None-Match matches" do
      resp = build_response("/", method: "POST", "HTTP_IF_NONE_MATCH" => '"abc"')
      expect { resp.etag("abc") }.to raise_error(Nextrb::PreconditionFailed)
    end

    it "raises PreconditionFailed when If-Match does not match the current etag" do
      resp = build_response("/", method: "GET", "HTTP_IF_MATCH" => '"other"')
      expect { resp.etag("abc") }.to raise_error(Nextrb::PreconditionFailed)
    end

    it "does not raise when If-Match matches the current etag" do
      resp = build_response("/", method: "GET", "HTTP_IF_MATCH" => '"abc"')
      expect { resp.etag("abc") }.not_to raise_error
    end
  end

  describe "#last_modified conditional handling" do
    let(:time) { Time.at(1_700_000_000) }

    it "raises NotModified when If-Modified-Since is at or after the given time" do
      resp = build_response("/", "HTTP_IF_MODIFIED_SINCE" => time.httpdate)
      expect { resp.last_modified(time) }.to raise_error(Nextrb::NotModified)
    end

    it "does not raise when If-Modified-Since predates the given time" do
      resp = build_response("/", "HTTP_IF_MODIFIED_SINCE" => (time - 60).httpdate)
      expect { resp.last_modified(time) }.not_to raise_error
    end

    it "skips the If-Modified-Since check when If-None-Match is present" do
      resp = build_response("/", "HTTP_IF_MODIFIED_SINCE" => time.httpdate, "HTTP_IF_NONE_MATCH" => '"abc"')
      expect { resp.last_modified(time) }.not_to raise_error
    end

    it "raises PreconditionFailed when If-Unmodified-Since predates the given time" do
      resp = build_response("/", "HTTP_IF_UNMODIFIED_SINCE" => (time - 60).httpdate)
      expect { resp.last_modified(time) }.to raise_error(Nextrb::PreconditionFailed)
    end

    it "does not raise when If-Unmodified-Since is at or after the given time" do
      resp = build_response("/", "HTTP_IF_UNMODIFIED_SINCE" => time.httpdate)
      expect { resp.last_modified(time) }.not_to raise_error
    end
  end

  describe "file serving" do
    let(:fixture_path) { File.expand_path("../../fixtures/static/hello.txt", __dir__) }

    it "serves the full file with a last-modified header and correct length" do
      resp = build_response("/hello.txt")
      req = Nextrb::Request.new(Rack::MockRequest.env_for("/hello.txt"))
      resp.send_file(req, fixture_path)
      status, headers, = resp.finish
      expect(status).to eq(200)
      expect(headers["content-length"]).to eq("13")
      expect(headers["last-modified"]).not_to be_nil
    end

    it "serves a byte range with 206, a content-range header, and the range's length" do
      req = Nextrb::Request.new(Rack::MockRequest.env_for("/hello.txt", "HTTP_RANGE" => "bytes=0-4"))
      resp = build_response("/hello.txt", "HTTP_RANGE" => "bytes=0-4")
      resp.send_file(req, fixture_path)
      expect(resp.status).to eq(206)
      expect(resp.headers["content-range"]).to eq("bytes 0-4/13")
      expect(resp.headers["content-length"]).to eq("5")
    end

    it "returns 416 for an unsatisfiable range" do
      req = Nextrb::Request.new(Rack::MockRequest.env_for("/hello.txt", "HTTP_RANGE" => "bytes=9999-10000"))
      resp = build_response("/hello.txt", "HTTP_RANGE" => "bytes=9999-10000")
      resp.send_file(req, fixture_path)
      expect(resp.status).to eq(416)
      expect(resp.headers["content-range"]).to eq("bytes */13")
    end

    it "raises NotFound for a missing file" do
      req = Nextrb::Request.new(Rack::MockRequest.env_for("/nope.txt"))
      resp = build_response("/nope.txt")
      expect { resp.send_file(req, "/no/such/file.txt") }.to raise_error(Nextrb::NotFound)
    end

    it "sets a content-disposition header when sent as an attachment" do
      req = Nextrb::Request.new(Rack::MockRequest.env_for("/hello.txt"))
      resp = build_response("/hello.txt")
      resp.send_file(req, fixture_path, attachment: true)
      expect(resp.headers["Content-Disposition"]).to eq('attachment; filename="hello.txt"')
    end
  end

  describe "#finish" do
    it "computes content-length from the body" do
      resp = build_response
      resp.text("hello world")
      status, headers, body = resp.finish
      expect(status).to eq(200)
      expect(headers["content-length"]).to eq("11")
      expect(body).to eq(["hello world"])
    end

    it "clears the body and content headers for a 204" do
      resp = build_response
      resp.text("hi")
      resp.status(204)
      status, headers, body = resp.finish
      expect(status).to eq(204)
      expect(headers).not_to have_key("content-length")
      expect(headers).not_to have_key("content-type")
      expect(body).to eq([])
    end
  end
end
