# frozen_string_literal: true

require "rack/mock_request"

class RoutesPageSpecApp < StirFry::App
  get("/") { |response:, **| response.text("root") }
  post("/todos", description: "Creates a todo") { |response:, **| response.text("create") }
  delete("/todos/:id") { |response:, **| response.text("destroy") }
end

RSpec.describe StirFry::Pages::RoutesPage do
  let(:application) { RoutesPageSpecApp.new(Rack::MockRequest.env_for("/")) }
  let(:html) { described_class.new(application: application).render }

  it "renders one styled row per verb/path pair" do
    expect(html.scan('class="route-list__item"').length).to eq(3)
  end

  it "tags each row with its HTTP verb for styling" do
    expect(html).to include('<span class="route-list__verb" data-verb="POST">POST</span>')
    expect(html).to include('<code class="route-list__path">/todos</code>')
  end

  it "renders the description when the route has one" do
    expect(html).to include('<span class="route-list__description">Creates a todo</span>')
  end

  it "omits the description element when the route has none" do
    expect(html.scan('class="route-list__description"').length).to eq(1)
  end

  it "summarises the route count" do
    expect(html).to include("3 registered routes")
  end
end
