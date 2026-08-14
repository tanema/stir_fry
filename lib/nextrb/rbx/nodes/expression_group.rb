# frozen_string_literal: true

module Nextrb
  module RBX
    module Nodes
      # ExpressionGroup is a series of expressions inside {}
      class ExpressionGroup < Base
        attr_accessor :members
        attr_reader :outer_template, :inner_template

        def initialize(members:, inner_template: RAW, outer_template: OUTPUT_EXPR)
          super()
          @members = members
          @outer_template = outer_template
          @inner_template = inner_template
        end

        def precompile
          [
            ExpressionGroup.new(
              members: precompile_members,
              outer_template: outer_template,
              inner_template: inner_template
            )
          ]
        end

        def compile
          outer_template % (inner_template % members.map(&:compile).join)
        end

        private

        def precompile_members
          compact(members.map(&:precompile).flatten).map(&method(:transform_member))
        end

        def transform_member(node)
          case node
          when Raw
            Raw.new(node.content, template: EXPR_STRING)
          when ComponentElement
            ComponentElement.new(name: node.name, members: node.members, children: node.children, template: ComponentElement::EXPR_STRING)
          when ExpressionGroup
            ExpressionGroup.new(members: node.members, inner_template: node.inner_template, outer_template: RAW)
          else
            node
          end
        end
      end
    end
  end
end
