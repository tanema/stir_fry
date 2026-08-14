# frozen_string_literal: true

module Nextrb
  module RBX
    module Nodes
      #  AbstractNode is the base class of all parsed elements
      class Base
        class PrecompileRequired < StandardError
        end

        def precompile
          [self]
        end

        def compile
          raise PrecompileRequired, "#{self.class.name} must be precompiled first"
        end

        private

        def compact(nodes)
          curr_raw = nil
          (nodes.each_with_object([]) do |node, compacted|
            if node.is_a?(Raw)
              curr_raw&.merge(node)
              curr_raw ||= node
            else
              compacted.push(curr_raw, node)
              curr_raw = nil
            end
          end + [curr_raw]).compact
        end
      end
    end
  end
end
