# frozen_string_literal: true

module Nextrb
  module RBX
    module Nodes
      class Text < AbstractNode
        attr_accessor :content

        def initialize(content)
          super
          @content = content
        end

        def precompile
          [Raw.new(content.gsub('"', '\\"').gsub("'", "\\\\'"))]
        end
      end
    end
  end
end
