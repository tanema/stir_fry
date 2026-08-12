# frozen_string_literal: true

module Nextrb
  module RBX
    module Nodes
      class Expression < AbstractNode
        attr_accessor :content

        def initialize(content)
          super
          @content = content
        end

        def compile
          content
        end
      end
    end
  end
end
