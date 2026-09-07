# frozen_string_literal: true

require "rack/mock_request"

RSpec.describe StirFry::Request do
  def build_request(path = "/", opts = {})
    described_class.new(Rack::MockRequest.env_for(path, opts))
  end

  describe "#path" do
    it "unescapes the path info" do
      expect(build_request("/hello%20world").path).to eq("/hello world")
    end
  end

  describe "content negotiation" do
    it "matches the accept header against each mime predicate" do
      req = build_request("/", "HTTP_ACCEPT" => "application/json, text/plain;q=0.5")
      expect(req.json?).to be true
      expect(req.text?).to be true
      expect(req.html?).to be false
      expect(req.xml?).to be false
      expect(req.csv?).to be false
    end

    it "does not match anything when there is no accept header" do
      req = build_request("/")
      expect(req.json?).to be false
      expect(req.html?).to be false
      expect(req.accept?("application/json")).to be false
    end
  end

  describe "#params" do
    it "returns parsed query params on the happy path" do
      req = build_request("/?name=jack")
      expect(req.params).to eq("name" => "jack")
    end

    it "raises BadRequest with an escaped message for conflicting param types" do
      req = build_request("/?a[]=1&a[b]=2")
      expect { req.params }.to raise_error(StirFry::BadRequest, /Invalid query parameters/)
    end
  end
end
