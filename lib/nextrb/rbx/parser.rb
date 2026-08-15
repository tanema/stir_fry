# frozen_string_literal: true

module Nextrb
  module RBX
    # Parser takes in a tokenized stream and build semantic reasoning from it for
    # rebuilding the html output with enriched components.
    class Parser
      class ParseError < StandardError; end

      attr_reader :tokens
      attr_accessor :position

      def self.parse(tokens)
        root = new(tokens).parse
        root.precompile.compile
      end

      def initialize(tokens)
        @tokens = tokens
        @position = 0
      end

      def parse
        validate_tokens!
        Nodes::Root.new(parse_tokens)
      end

      def parse_tokens
        results = []

        while (result = parse_token)
          results << result
        end

        results
      end

      def parse_token
        parse_text || parse_newline || parse_expression || parse_tag || parse_declaration
      end

      def parse_text
        return unless (token = take(:TEXT))

        Nodes::Raw.new(token[1].gsub("'", "\\\\'"))
      end

      def parse_expression
        return unless take(:OPEN_EXPRESSION)

        members = []

        eventually!(:CLOSE_EXPRESSION)
        members << (parse_expression_body || parse_tag) until take(:CLOSE_EXPRESSION)

        Nodes::ExpressionGroup.new(members: members)
      end

      def parse_expression!
        peek!(:OPEN_EXPRESSION)
        parse_expression
      end

      def parse_expression_body
        return unless (token = take(:EXPRESSION_BODY))

        Nodes::Expression.new(token[1])
      end

      def parse_tag
        return unless take(:OPEN_TAG_DEF)

        details = take!(:TAG_DETAILS)[1]
        attr_class = details[:type] == :component ? Nodes::ComponentProp : Nodes::HTMLAttr
        members = take_all(:NEWLINE).map { Nodes::Newline.new }.concat(parse_attrs(attr_class))
        take!(:CLOSE_TAG_DEF)
        if details[:type] == :component
          Nodes::ComponentElement.new(name: details[:component_class], members: members, children: parse_children)
        else
          Nodes::HTMLElement.new(name: details[:name], members: members, children: parse_children)
        end
      end

      def parse_attrs(attr_class)
        return [] unless take(:OPEN_ATTRS)

        attrs = []

        eventually!(:CLOSE_ATTRS)
        attrs << (parse_splat_attr || parse_newline || parse_attr(attr_class)) until take(:CLOSE_ATTRS)

        attrs
      end

      def parse_splat_attr
        return unless take(:OPEN_ATTR_SPLAT)

        expression = parse_expression!
        take!(:CLOSE_ATTR_SPLAT)

        expression
      end

      def parse_newline
        return unless take(:NEWLINE)

        Nodes::Raw.new("\n")
      end

      def parse_attr(attr_class)
        name = take!(:ATTR_NAME)[1]
        value = nil

        if take(:OPEN_ATTR_VALUE)
          value = parse_text || parse_expression
          raise ParseError, "Missing attribute value" unless value

          take(:CLOSE_ATTR_VALUE)
        else
          value = default_empty_attr_value
        end

        attr_class.new(name, value)
      end

      def parse_children
        children = []

        eventually!(:OPEN_TAG_END)
        children << parse_token until take(:OPEN_TAG_END)

        take(:TAG_NAME)
        take!(:CLOSE_TAG_END)

        children
      end

      private

      def parse_declaration
        return unless (token = take(:DECLARATION))

        Nodes::Raw.new(token[1].gsub("'", "\\\\'"))
      end

      def take(token_name)
        return unless (token = peek(token_name))

        self.position += 1
        token
      end

      def take_all(token_name)
        result = []
        while (token = take(token_name))
          result << token
        end
        result
      end

      def take!(token_name)
        take(token_name) || unexpected_token!(token_name)
      end

      def peek(token_name)
        return unless (token = tokens[position]) && token[0] == token_name

        token
      end

      def peek!(token_name)
        peek(token_name) || unexpected_token!(token_name)
      end

      def eventually!(token_name)
        tokens[position..].first { |t| t[0] == token_name } ||
          raise(ParseError, "Expected to find a #{token_name} but never did")
      end

      def default_empty_attr_value
        Nodes::Raw.new("")
      end

      def error_window
        window_start = [position - 2, 0].max
        window_end = [position + 2, tokens.length - 1].min
        err_token_window(window_start, window_end)
      end

      def err_token_window(wstart, wend)
        tokens[wstart..wend].map.with_index do |token, i|
          "#{wstart + i == position ? "=>" : "  "} #{token}"
        end.join("\n")
      end

      def unexpected_token!(expected_token)
        raise(ParseError, "Unexpected token #{tokens[position][0]}, expecting #{expected_token}\n#{error_window}")
      end

      def validate_tokens!
        validate_all_tags_close!
      end

      def validate_all_tags_close!
        open_count = tokens.count { |t| t[0] == :OPEN_TAG_DEF }
        close_count = tokens.count { |t| t[0] == :OPEN_TAG_END }
        return unless open_count != close_count

        raise(ParseError,
              %(#{open_count - close_count} tags fail to close. All tags must close,
              either <NAME></NAME> or self-closing <NAME />))
      end
    end
  end
end
