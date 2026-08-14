# frozen_string_literal: true

RSpec.describe Nextrb::RBX::ComponentResolver do
  describe "#component_class" do
    subject(:resolver) { described_class.new }

    before do
      stub_const("ButtonComponent", Class.new)
      stub_const("Things::ButtonComponent", Class.new)
      resolver.register(ButtonComponent)
      resolver.register(Things::ButtonComponent)
    end

    it "resolves strings to constants ending with Component" do
      result = resolver.component_class("Button")
      expect(result).to eq ButtonComponent
    end

    it "is nil if no matching constant exists" do
      result = resolver.component_class("SomeNonexistentThing")
      expect(result).to be_nil
    end

    it "expands dot-notation to Ruby's :: namespace notation" do
      result = resolver.component_class("Things.Button")
      expect(result).to eq Things::ButtonComponent
    end
  end
end
