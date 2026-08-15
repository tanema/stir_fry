# frozen_string_literal: true

RSpec.describe Nextrb::RBX::Nodes::ExpressionGroup do
  describe "#compile" do
    it "compiles a bare expression to a plain output statement" do
      group = described_class.new(members: [Nextrb::RBX::Nodes::Expression.new("about_path")])

      expect(group.compile).to eq "_nextrbout << Array(about_path).join\n"
    end

    it "joins tag content embedded inside a ruby block with valid concatenation" do
      group = described_class.new(members: [
                                    Nextrb::RBX::Nodes::Expression.new("[1, 2, 3].map { |n| "),
                                    Nextrb::RBX::Nodes::Raw.new("<li>", template: Nextrb::RBX::Nodes::EXPR_STRING),
                                    described_class.new(
                                      members: [Nextrb::RBX::Nodes::Expression.new("n")],
                                      inner_template: Nextrb::RBX::Nodes::RAW,
                                      outer_template: Nextrb::RBX::Nodes::RAW
                                    ),
                                    Nextrb::RBX::Nodes::Raw.new("</li>", template: Nextrb::RBX::Nodes::EXPR_STRING),
                                    Nextrb::RBX::Nodes::Expression.new(" }")
                                  ])

      compiled = group.compile

      expect(compiled).to eq(
        "_nextrbout << Array([1, 2, 3].map { |n| ('<li>').to_s + (n).to_s + ('</li>').to_s }).join\n"
      )

      _nextrbout = String.new # rubocop:disable Lint/UnderscorePrefixedVariableName -- name must match the compiled code
      eval(compiled, binding) # rubocop:disable Security/Eval
      expect(_nextrbout).to eq "<li>1</li><li>2</li><li>3</li>"
    end
  end
end
