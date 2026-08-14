# frozen_string_literal: true

module Nextrb
  module RBX
    module Nodes
      # Root is the main node returned by parse that contains everything
      class Root < Base
        attr_accessor :children

        def initialize(children)
          super()
          @children = children
        end

        def precompile
          Root.new(compact(children.map(&:precompile).flatten))
        end

        def compile
          "#{children.map(&:compile).join}\n@output_buffer.to_s"
        end
      end
    end
  end
end
