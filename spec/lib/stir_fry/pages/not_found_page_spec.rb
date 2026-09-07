# frozen_string_literal: true

require "rack/mock_request"

class NotFoundPageSpecApp < StirFry::App
  get("/") { |response:, **| response.text("root") }
  get("/widgets/:id") { |response:, **| response.text("show") }
end

RSpec.describe StirFry::Pages::NotFoundPage do
  let(:application) { NotFoundPageSpecApp.new(Rack::MockRequest.env_for("/")) }
  let(:html) { described_class.new(application: application).render }

  it "keeps the 404 error block" do
    expect(html).to include('<p class="error-page__code">404</p>')
  end

  it "lists the registered routes with verb badges below the error" do
    expect(html).to include('<p class="route-list__caption">Registered routes</p>')
    expect(html).to include('<span class="route-list__verb" data-verb="GET">GET</span>')
    expect(html).to include('<code class="route-list__path">/widgets/:id</code>')
    expect(html.scan('class="route-list__item"').length).to eq(2)
  end
end
