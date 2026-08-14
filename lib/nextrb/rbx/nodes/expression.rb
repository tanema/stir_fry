# frozen_string_literal: true

module Nextrb
  module RBX
    module Nodes
      # Expression is a single value inside of {} brackets express a ruby value.
      class Expression < Base
        attr_accessor :content

        def initialize(content)
          super()
          @content = content
        end

        def compile
          content
        end
      end
    end
  end
end
