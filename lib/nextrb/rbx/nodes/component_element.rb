# frozen_string_literal: true

module Nextrb
  module RBX
    module Nodes
      # ComponentElement captures a tag that is referencing a ruby component
      class ComponentElement < Base
        attr_reader :template

        attr_accessor :name, :members, :children

        def initialize(name:, members: [], children: [], template: OUTPUT_EXPR)
          super()
          @name = name
          @members = members
          @children = children
          @template = template
        end

        def precompile
          [ComponentElement.new(
            name: name,
            members: precompile_members,
            children: precompile_children
          )]
        end

        def compile
          template % "::#{name}.new(#{compile_members})#{children_block}.render"
        end

        def children_block
          return "" unless children.any?

          ".capture do |_nextrbout|\n#{children.map(&:compile).join}end"
        end

        def compile_members
          members.map do |member|
            member.is_a?(ExpressionGroup) ? "**#{member.compile}" : member.compile
          end.join(",")
        end

        private

        def precompile_members
          members.map { |node| node.is_a?(ExpressionGroup) ? group_node(node) : node }
                 .map(&:precompile).flatten
        end

        def group_node(node)
          ExpressionGroup.new(
            members: node.members,
            inner_template: RAW,
            outer_template: RAW
          )
        end

        def precompile_children
          compact(children.map(&:precompile).flatten)
        end
      end
    end
  end
end
