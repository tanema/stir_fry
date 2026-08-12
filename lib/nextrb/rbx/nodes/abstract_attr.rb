# frozen_string_literal: true

module Nextrb
  module RBX
    module Nodes
      class AbstractAttr < AbstractNode
        attr_accessor :name, :value

        def initialize(name, value)
          super
          @name = name
          @value = value
        end
      end
    end
  end
end
