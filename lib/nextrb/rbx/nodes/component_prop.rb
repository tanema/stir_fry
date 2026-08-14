# frozen_string_literal: true

module Nextrb
  module RBX
    module Nodes
      # ComponentProp captures arguments passed to a component element
      class ComponentProp < Base
        attr_accessor :name, :value

        def initialize(name, value)
          super()
          @name = name
          @value = value
        end

        def precompile
          [ComponentProp.new(name, precompile_value)]
        end

        def compile
          key = name.gsub("::", "/").gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                    .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                    .tr("-", "_")
                    .downcase
          "#{key}: #{value.compile}"
        end

        private

        def precompile_value
          case node = value.precompile.first
          when Raw then Raw.new(node.content, template: EXPR_STRING)
          when ExpressionGroup then group_node(node)
          else node
          end
        end

        def group_node(node)
          ExpressionGroup.new(
            members: node.members,
            inner_template: node.inner_template,
            outer_template: RAW
          )
        end
      end
    end
  end
end
