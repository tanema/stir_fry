# frozen_string_literal: true

require "rack/mock_request"

module AppSpecFixtures
  def self.handler_calls
    @handler_calls ||= []
  end

  class Ping
    def self.get(request:, response:, **)
      AppSpecFixtures.handler_calls << request.path_info
      response.text("pong")
    end
  end

  class Echo
    def self.get(response:, id:, **)
      response.text("echo-#{id}")
    end
  end

  class TraceMiddleware
    def initialize(app, trace, label)
      @app = app
      @trace = trace
      @label = label
    end

    def call(env)
      @trace << @label
      @app.call(env)
    end
  end

  class HeaderMiddleware
    def initialize(app, name, value)
      @app = app
      @name = name
      @value = value
    end

    def call(env)
      status, headers, body = @app.call(env)
      headers[@name] = @value
      [status, headers, body]
    end
  end

  class BlockingMiddleware
    def initialize(app) = @app = app
    def call(_env) = raise Nextrb::Unauthorized
  end
end

class AppSpecApp < Nextrb::App
  def self.trace
    @trace ||= []
  end

  use(AppSpecFixtures::TraceMiddleware, trace, "global")

  static(File.expand_path("../../fixtures/static", __dir__))
  static(File.expand_path("../../fixtures/static_prefixed", __dir__), path: "/assets")

  get("/plain") { |response:, **| response.text("plain-ok") }

  get("/conditional") do |response:, **|
    response.last_modified(Time.at(1_700_000_000))
    response.text("fresh")
  end

  get("/echo/:id", AppSpecFixtures::Echo)

  get("/items/:category/:id") do |category:, id:, response:, **|
    response.text("#{category}/#{id}")
  end

  scope do
    use AppSpecFixtures::HeaderMiddleware, "X-Powered-By", "nextrb"
    get("/wrapped") do |response:, **|
      response.text("wrapped-ok")
    end
  end

  scope do
    use AppSpecFixtures::BlockingMiddleware
    get("/blocked", AppSpecFixtures::Ping)
  end

  scope("/scoped") do
    use(AppSpecFixtures::TraceMiddleware, trace, "outer")

    scope do
      use AppSpecFixtures::TraceMiddleware, trace, "inner"
      get("/order") do |response:, **|
        response.text("order-ok")
      end
    end
    get("/nested") { |response:, **| response.text("nested-ok") }
  end
end

class OtherAppSpecApp < Nextrb::App
  get("/only-here") { |response:, **| response.text("isolated-ok") }
end

RSpec.describe Nextrb::App do
  let(:mock) { Rack::MockRequest.new(AppSpecApp) }

  before do
    AppSpecFixtures.handler_calls.clear
    AppSpecApp.trace.clear
  end

  it "dispatches routes with no scoped middleware" do
    resp = mock.get("/plain")
    expect(resp.status).to eq(200)
    expect(resp.body).to eq("plain-ok")
  end

  it "returns 304 with an empty body when If-Modified-Since matches last_modified" do
    resp = mock.get("/conditional")
    expect(resp.status).to eq(200)
    expect(resp.body).to eq("fresh")

    resp = mock.get("/conditional", "HTTP_IF_MODIFIED_SINCE" => Time.at(1_700_000_000).httpdate)
    expect(resp.status).to eq(304)
    expect(resp.body).to eq("")
  end

  it "passes a captured route param as a keyword argument to a class-based handler" do
    resp = mock.get("/echo/42")
    expect(resp.status).to eq(200)
    expect(resp.body).to eq("echo-42")
  end

  it "passes multiple captured route params as keyword arguments to a block handler" do
    resp = mock.get("/items/books/7")
    expect(resp.status).to eq(200)
    expect(resp.body).to eq("books/7")
  end

  it "runs route-level middleware around the handler" do
    resp = mock.get("/wrapped")
    expect(resp.status).to eq(200)
    expect(resp.body).to eq("wrapped-ok")
    expect(resp.headers["X-Powered-By"]).to eq("nextrb")
  end

  it "short-circuits the handler when route-level middleware raises" do
    resp = mock.get("/blocked", "HTTP_ACCEPT" => "application/json")
    expect(resp.status).to eq(401)
    expect(AppSpecFixtures.handler_calls).to be_empty
  end

  it "prefixes routes declared inside a scope" do
    resp = mock.get("/scoped/nested")
    expect(resp.status).to eq(200)
    expect(resp.body).to eq("nested-ok")
  end

  it "runs global, then scope, then route-level middleware, outer to inner" do
    resp = mock.get("/scoped/order")
    expect(resp.status).to eq(200)
    expect(AppSpecApp.trace).to eq(%w[global outer inner])
  end

  it "runs global middleware even for requests that never match a route" do
    resp = mock.get("/does-not-exist")
    expect(resp.status).to eq(404)
    expect(AppSpecApp.trace).to eq(%w[global])
  end

  it "serves static files ahead of the router" do
    resp = mock.get("/hello.txt")
    expect(resp.status).to eq(200)
    expect(resp.body).to eq("hello static\n")
  end

  it "falls through to the router's 404 page when no static file or route matches" do
    resp = mock.get("/nope.txt", "HTTP_ACCEPT" => "application/json")
    expect(resp.status).to eq(404)
    expect(JSON.parse(resp.body)["error"]).to eq("not_found")
  end

  it "serves a static root under a prefix, stripped from the on-disk lookup path" do
    resp = mock.get("/assets/nested/world.txt")
    expect(resp.status).to eq(200)
    expect(resp.body).to eq("hello prefixed\n")
  end

  it "does not serve a prefixed static root at its unprefixed path" do
    expect(mock.get("/nested/world.txt").status).to eq(404)
  end

  it "keeps routes and middleware isolated per subclass" do
    resp = Rack::MockRequest.new(OtherAppSpecApp).get("/only-here")
    expect(resp.status).to eq(200)
    expect(resp.body).to eq("isolated-ok")
    expect(Rack::MockRequest.new(AppSpecApp).get("/only-here").status).to eq(404)
  end
end
