# frozen_string_literal: true

module Nextrb
  module RBX
    module Nodes
      class Newline < AbstractNode
        def compile
          "\n"
        end
      end
    end
  end
end
