# frozen_string_literal: true

module Nextrb
  # RBX is a module for handling enriched html parsing in a same manner that jsx does
  module RBX
    autoload :Lexer, "nextrb/rbx/lexer"
    autoload :Parser, "nextrb/rbx/parser"
    autoload :Nodes, "nextrb/rbx/nodes"
    autoload :ComponentResolver, "nextrb/rbx/component_resolver"

    @resolver = ComponentResolver.new
    class << self
      attr_reader :resolver

      def parse(template_name, template, rsvl = resolver)
        Parser.parse(Lexer.tokenize(template, rsvl))
      rescue StandardError => e
        raise "Error in #{template_name}: #{e}"
      end

      def register_component(klass)
        raise "cannot register a non-component #{klass.name}" unless klass < ::Nextrb::Component

        resolver.register(klass)
      end
    end
  end
end
