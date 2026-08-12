# frozen_string_literal: true

module Nextrb
  module RBX
    module Nodes
      class HTMLElement < AbstractElement
        # Referenced from https://html.spec.whatwg.org/#void-elements
        HTML_VOID_ELEMENTS = %w[area base br col embed hr img input link meta source track wbr].freeze

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
          nodes = [Raw.new("<#{name}")]
          nodes.concat(precompile_members)
          nodes << Raw.new(">")
          nodes
        end

        def precompile_members
          members.map { |node| node.is_a? ExpressionGroup ? grou_node(node) : node }
                 .map(&:precompile).flatten
        end

        def group_node(node)
          ExpressionGroup.new(
            node.members,
            inner_template: "Rbexy::Runtime.splat_attrs(%s)",
            outer_template: ExpressionGroup::OUTPUT_SAFE
          )
        end
      end
    end
  end
end
