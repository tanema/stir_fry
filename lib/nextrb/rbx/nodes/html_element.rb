# frozen_string_literal: true

module Nextrb
  module RBX
    module Nodes
      # HTMLElement is an HTML tag
      class HTMLElement < Base
        # Referenced from https://html.spec.whatwg.org/#void-elements
        HTML_VOID_ELEMENTS = %w[
          area base br col embed hr img input link meta source track wbr
        ].freeze

        attr_accessor :name, :members, :children

        def initialize(name:, members:, children:)
          super()
          @name = name
          @members = members || []
          @children = children
        end

        def precompile
          nodes = precompile_open_tag
          if !void? || children.length.positive?
            nodes.concat(children.map(&:precompile).flatten)
            nodes << Raw.new("</#{name}>")
          end
          nodes
        end

        private

        def void?
          HTML_VOID_ELEMENTS.include?(name)
        end

        def precompile_open_tag
          [Raw.new("<#{name}")] + precompile_attributes + [Raw.new(">")]
        end

        def precompile_attributes
          members.map { |node| node.is_a?(ExpressionGroup) ? attribute_node(node) : node }
                 .map(&:precompile).flatten
        end

        def attribute_node(node)
          ExpressionGroup.new(
            members: node.members,
            inner_template: "tag_kwargs(%s)",
            outer_template: OUTPUT_EXPR
          )
        end
      end
    end
  end
end
