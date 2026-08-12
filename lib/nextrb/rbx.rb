# frozen_string_literal: true

module Nextrb
  module RBX
    autoload :Lexer, "nextrb/rbx/lexer"
    autoload :Parser, "nextrb/rbx/parser"
    autoload :Nodes, "nextrb/rbx/nodes"
    autoload :ComponentResolver, "nextrb/rbx/component_resolver"

    class << self
      def parse(template)
        resolver = ComponentResolver.new
        tokens = Lexer.new(template, resolver).tokenize
        root = Parser.new(tokens).parse
        root.precompile.compile

        # @output_buffer = String.new(buffer)
        # @output_buffer.encode!
        # @output_buffer << ERB::Util.unwrapped_html_escape(value)
        # instance_eval(code)
      end
    end
  end
end
