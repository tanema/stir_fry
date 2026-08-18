# frozen_string_literal: true

class FakeComponent
  include Nextrb::Component::Options

  class << self
    attr_accessor :template
  end

  def initialize
    @name = "bobby"
    @dynamic_class = "person"
    @more_attrs = { disabled: true }
  end

  def _nextrbout
    @_nextrbout ||= String.new
  end

  def click_title
    "Click me"
  end

  def link_to(_path)
    yield
  end

  def capture(&)
    @child_buffer = String.new
    yield(@child_buffer)
    self
  end

  def render
    _render_with_block { @child_buffer }
  end

  def _render_with_block
    instance_eval(self.class.template)
    _nextrbout
  end
end

class OtherComponent < FakeComponent
  @template = Nextrb::RBX.parse("spec_template", "<h1>{yield}</h1>")
end

RSpec.describe Nextrb::RBX do
  describe ".parse" do
    let(:resolver) do
      Class.new do
        def component?(name) = name == "Banner"
        def component_class(_name) = OtherComponent
      end.new
    end

    def render(template)
      FakeComponent.template = described_class.parse("spec_template", template)
      FakeComponent.new.render
    end

    it "renders a ruby block that embeds a tag around a block-local variable" do
      template = "<ul>{[1, 2, 3].map { |n| <li>{n}</li> }}</ul>"

      expect(render(template)).to eq "<ul><li>1</li><li>2</li><li>3</li></ul>"
    end

    it "renders a do/end block that embeds a tag around a method call" do
      template = <<~RBX
        {link_to "/about" do
          <span>{click_title}</span>
        end}
      RBX
      expect(render(template)).to eq "<span>Click me</span>"
    end

    it "can us plain ruby code in brackets" do
      template = '<p class={@dynamic_class}>Hello {"world".upcase}</p>'
      expect(render(template)).to eq "<p class=\"person\">Hello WORLD</p>"
    end

    it "can splat attributes" do
      template = %(<div {**{class: "myClass"}} {**@more_attrs}></div>)
      expect(render(template)).to eq %(<div class="myClass" disabled></div>)
    end

    it "can use tags inside expressions" do
      template = %(<div>{true && <h1>Welcome</h1>}{false ? <p>Option One</p> : <p>Option Two</p>}</div>)
      expect(render(template)).to eq %(<div><h1>Welcome</h1><p>Option Two</p></div>)
    end

    it "can use components" do
      template = %(<Banner>{@name}</Banner>)
      FakeComponent.template = described_class.parse("spec_template", template, resolver)
      result = FakeComponent.new.render
      expect(result).to eq %(<h1>bobby</h1>)
    end
  end
end
