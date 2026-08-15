# frozen_string_literal: true

RSpec.describe Nextrb::RBX::ComponentResolver do
  describe "#component_class" do
    subject(:resolver) { described_class.new }

    before do
      stub_const("Button", Class.new)
      stub_const("Things::Button", Class.new)
      resolver.register(Button)
      resolver.register(Things::Button)
    end

    it "resolves strings to constants ending with Component" do
      result = resolver.component_class("Button")
      expect(result).to eq Button
    end

    it "is nil if no matching constant exists" do
      result = resolver.component_class("SomeNonexistentThing")
      expect(result).to be_nil
    end

    it "expands dot-notation to Ruby's :: namespace notation" do
      result = resolver.component_class("Things.Button")
      expect(result).to eq Things::Button
    end
  end
end
