# frozen_string_literal: true

module Nextrb
  module RBX
    module Nodes
      class ComponentProp < AbstractAttr
        def precompile
          [ComponentProp.new(name, precompile_value)]
        end

        def compile
          key = name.gsub(/::/, "/").gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                    .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                    .tr("-", "_")
                    .downcase
          "#{key}: #{value.compile}"
        end

        private

        def precompile_value
          case node = value.precompile.first
          when Raw then raw_node(node)
          when ExpressionGroup then group_node(node)
          else node
          end
        end

        def raw_node(node)
          Raw.new(
            node.content,
            template: Raw::EXPR_STRING
          )
        end

        def group_node(node)
          ExpressionGroup.new(
            node.members,
            outer_template: ExpressionGroup::SUB_EXPR,
            inner_template: node.inner_template
          )
        end
      end
    end
  end
end
