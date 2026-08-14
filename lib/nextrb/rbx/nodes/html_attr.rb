# frozen_string_literal: true

module Nextrb
  module RBX
    module Nodes
      # HTMLAttr is a single attribute setting on an HTML tag
      class HTMLAttr < Base
        attr_accessor :name, :value

        def initialize(name, value)
          super()
          @name = name
          @value = value
        end

        def precompile
          [Raw.new(" #{name}=\"")] + value.precompile + [Raw.new("\"")]
        end
      end
    end
  end
end
