# frozen_string_literal: true

module Nextrb
  module RBX
    module Nodes
      class ExpressionGroup < AbstractNode
        attr_accessor :members
        attr_reader :outer_template, :inner_template

        OUTPUT_UNSAFE = "@output_buffer.concat(Rbexy::Runtime.expr_out(%s));"
        OUTPUT_SAFE = "@output_buffer.safe_concat(Rbexy::Runtime.expr_out(%s));"
        RAW = "%s"
        SUB_EXPR = RAW
        SUB_EXPR_OUT = "Rbexy::Runtime.expr_out(%s)"

        def initialize(members, outer_template: OUTPUT_UNSAFE, inner_template: RAW)
          super
          @members = members
          @outer_template = outer_template
          @inner_template = inner_template
        end

        def precompile
          [
            ExpressionGroup.new(
              precompile_members,
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
          precompiled = compact(members.map(&:precompile).flatten)

          transformed = precompiled.map do |node|
            case node
            when Raw
              Raw.new(node.content, template: Raw::EXPR_STRING)
            when ComponentElement
              ComponentElement.new(node.name, node.members, node.children, template: ComponentElement::EXPR_STRING)
            when ExpressionGroup
              ExpressionGroup.new(node.members, outer_template: SUB_EXPR, inner_template: node.inner_template)
            else
              node
            end
          end

          transformed =  transformed.map.with_index do |curr, i|
            prev_i = i - 1
            next_i = i + 1

            if !curr.is_a?(map_type)
              curr
            elsif prev_i >= 0 && self[prev_i].is_a?(neighboring_type)
              ExpressionGroup.new(curr.members, outer_template: SUB_EXPR_OUT, inner_template: curr.inner_template)
            elsif next_i < length && self[next_i].is_a?(neighboring_type)
              ExpressionGroup.new(curr.members, outer_template: SUB_EXPR_OUT, inner_template: curr.inner_template)
            else
              curr
            end
          end

          transformed = insert_between_types(transformed, ExpressionGroup, Raw) do
            Expression.new("+")
          end
          insert_between_types(transformed, ComponentElement, Raw) do
            Expression.new("+")
          end
        end

        def insert_between_types(arr, type1, type2, &block)
          map.with_index do |curr, i|
            prev_i = i - 1

            if prev_i >= 0 && one_of_each_type?([self[prev_i], curr], [type1, type2])
              [block.call, curr]
            else
              [curr]
            end
          end.flatten
        end

        def one_of_each_type?(items_pair, types_pair)
          items_pair[0].is_a?(types_pair[0]) && items_pair[1].is_a?(types_pair[1]) ||
            items_pair[0].is_a?(types_pair[1]) && items_pair[1].is_a?(types_pair[0])
        end
      end
    end
  end
end
