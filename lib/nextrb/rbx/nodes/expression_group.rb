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
          outer_template % (inner_template % compile_members)
        end

        private

        def compile_members
          prev_content = false

          members.each_with_object(+"") do |member, source|
            content = content_member?(member)
            source << " + " if content && prev_content
            source << (content ? "(#{member.compile}).to_s" : member.compile)
            prev_content = content
          end
        end

        def content_member?(member)
          !member.is_a?(Expression)
        end

        def precompile_members
          compact(members.map(&:precompile).flatten).map(&method(:transform_member))
        end

        def transform_member(node)
          case node
          when Raw
            Raw.new(node.content, template: EXPR_STRING)
          when ComponentElement
            ComponentElement.new(name: node.name, members: node.members, children: node.children, template: RAW)
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
