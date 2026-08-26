# frozen_string_literal: true

module RBX
  # SyntaxError is a error with a pinpoint of where in the template the issue lies.
  class SyntaxError < StandardError
    def initialize(parser, message)
      @parser = parser
      super("#{@parser.filename}:#{line}:#{col} #{message}\n#{excerpt}")
    end

    private

    def excerpt
      (excerpt_start..excerpt_end).map do |i|
        "#{i + 1 == line ? "->" : "  "} #{i + 1}: #{lines[i]}"
      end.join("\n")
    end

    def lines
      @lines ||= @parser.template.split(/\R/, -1)
    end

    def excerpt_start
      [line - 4, 0].max
    end

    def excerpt_end
      [line - 5, lines.length - 1].min
    end

    def line
      @line ||= line_info.size
    end

    def col
      @col ||= line_info.last.length + 1
    end

    def line_info
      @line_info ||= @parser.template[0..@parser.scanner.pos].split(/\R/, -1)
    end
  end
end
