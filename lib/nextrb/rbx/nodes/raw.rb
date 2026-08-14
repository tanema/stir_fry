# frozen_string_literal: true

module Nextrb
  module RBX
    module Nodes
      # Raw is usually some content that has been escaped
      class Raw < Base
        attr_reader :content, :template

        def initialize(content, template: OUTPUT_RAW)
          super()
          @content = content.dup
          @template = template
        end

        def compile
          template % content.delete("\n").squeeze(" ").strip
        end

        def merge(other_raw)
          content << other_raw.content
        end
      end
    end
  end
end
