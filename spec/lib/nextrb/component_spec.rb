# frozen_string_literal: true

class ComponentSpecWrapper < Nextrb::Component
  template_source "<div>{ yield }</div>"
end

class ComponentSpecChild < Nextrb::Component
  def initialize(text:)
    super()
    @text = text
  end
  attr_reader :text

  template_source "<p>{ text }</p>"
end

RSpec.describe Nextrb::Component do
  it "does not escape captured child content rendered via yield" do
    result = ComponentSpecWrapper.new.capture do |buffer|
      buffer << ComponentSpecChild.new(text: "<script>alert(1)</script>").render
    end.render

    expect(result).to eq "<div><p>&lt;script&gt;alert(1)&lt;/script&gt;</p></div>"
  end
end
