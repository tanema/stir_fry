# frozen_string_literal: true

require "rack/mock_request"

class ComponentSpecWrapper < StirFry::Component
  template_source "<div>{ yield }</div>"
end

class ComponentSpecChild < StirFry::Component
  def initialize(text:, **args)
    super
    @text = text
  end
  attr_reader :text

  template_source "<p>{ text }</p>"
end

class ComponentSpecPage < StirFry::Component
  def initialize(name: "world", **args)
    super
    @name = name
  end
  attr_reader :name

  template_source "<p>hello { name }</p>"
end

RSpec.describe StirFry::Component do
  it "does not escape captured child content rendered via yield" do
    result = ComponentSpecWrapper.new.capture do |buffer|
      buffer << ComponentSpecChild.new(text: "<script>alert(1)</script>").render
    end.render

    expect(result).to eq "<div><p>&lt;script&gt;alert(1)&lt;/script&gt;</p></div>"
  end

  describe ".call" do
    def build_req_resp
      env = Rack::MockRequest.env_for("/")
      [StirFry::Request.new(env), StirFry::Response.new(env)]
    end

    it "forwards keyword args to .new and renders the result as html" do
      req, resp = build_req_resp

      ComponentSpecPage.call(name: "jack", request: req, response: resp)

      expect(resp.status).to eq(200)
      expect(resp.content_type).to eq("text/html")
      expect(resp.body).to eq(["<p>hello jack</p>"])
    end
  end
end
