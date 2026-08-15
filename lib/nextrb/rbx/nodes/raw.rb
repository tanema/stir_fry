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
          template % squeezed_content
        end

        def merge(other_raw)
          content << other_raw.content
        end

        private

        def squeezed_content
          squeezed = content.delete("\n").squeeze(" ")
          squeezed = squeezed.delete_prefix(" ") if content.match?(/\A[ \t]*\n/)
          squeezed = squeezed.delete_suffix(" ") if content.match?(/\n[ \t]*\z/)
          squeezed
        end
      end
    end
  end
end
