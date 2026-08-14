# frozen_string_literal: true

require "strscan"

module Nextrb
  module RBX
    # Lexer splits a string up into tokens that are usable by the parser
    class Lexer
      # Lexer::SyntaxError is raised when there is a problem splitting up the source
      # because it is poorly formatted.
      class SyntaxError < StandardError
        def initialize(lexer)
          super(
            "Invalid syntax: `#{lexer.scanner.peek(20)}`\n" \
            "Stack: #{lexer.stack}\n" \
            "Tokens: #{lexer.tokens}"
          )
        end
      end

      OPEN_EXPRESSION = /{/
      CLOSE_EXPRESSION = /}/
      EXPRESSION_CONTENT = /[^}{"'<]+/
      OPEN_TAG_DEF = %r{<(?!/)}
      OPEN_TAG_END = %r{</}
      CLOSE_TAG = %r{\s*/?>}
      CLOSE_SELF_CLOSING_TAG = %r{\s*/>}
      TAG_NAME = %r{/?[A-Za-z0-9\-_.]+}
      TEXT_CONTENT = /[^<{#]+/
      COMMENT = /^\p{Blank}*#.*(\n|\z)/
      WHITESPACE = /\s+/
      ATTR = /[A-Za-z0-9\-_.:]+/
      OPEN_ATTR_SPLAT = /{\*\*/
      ATTR_ASSIGNMENT = /=/
      DOUBLE_QUOTE = /"/
      SINGLE_QUOTE = /'/
      DOUBLE_QUOTED_TEXT_CONTENT = /[^"]+/
      SINGLE_QUOTED_TEXT_CONTENT = /[^']+/
      EXPRESSION_INTERNAL_TAG_PREFIXES = /(\s+(&&|\|\||\?|:|do|do\s*\|[^|]+\||{|{\s*\|[^|]+\|)\s+\z|\A\s*\z)/
      DECLARATION = /<![^>]*>/

      attr_reader :stack, :tokens, :scanner, :element_resolver, :template
      attr_accessor :curr_expr, :curr_default_text,
                    :curr_quoted_text

      def self.tokenize(template, resolver = ComponentResolver.new)
        new(template, resolver).tokenize
      end

      def initialize(template, resolver = ComponentResolver.new)
        @template = template
        @scanner = StringScanner.new(template)
        @element_resolver = resolver
        @stack = [:default]
        @curr_expr = ""
        @curr_default_text = ""
        @curr_quoted_text = ""
        @tokens = []
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def tokenize
        until scanner.eos?
          case stack.last
          when :default
            if scanner.scan(DECLARATION)
              tokens << [:DECLARATION, scanner.matched]
            elsif scanner.scan(OPEN_TAG_DEF)
              open_tag_def
            elsif scanner.scan(OPEN_EXPRESSION)
              open_expression
            elsif scanner.scan(COMMENT)
              tokens << [:NEWLINE]
            elsif scanner.check(TEXT_CONTENT)
              stack.push(:default_text)
            else
              raise SyntaxError, self
            end
          when :tag
            if scanner.scan(OPEN_TAG_DEF)
              open_tag_def
            elsif scanner.scan(OPEN_TAG_END)
              tokens << [:OPEN_TAG_END]
              stack.push(:tag_end)
            elsif scanner.scan(OPEN_EXPRESSION)
              open_expression
            elsif scanner.scan(COMMENT)
              tokens << [:NEWLINE]
            elsif scanner.check(TEXT_CONTENT)
              stack.push(:default_text)
            else
              raise SyntaxError, self
            end
          when :default_text
            raise SyntaxError, self unless scanner.scan(TEXT_CONTENT)

            self.curr_default_text += scanner.matched
            if scanner.matched.end_with?("\\") && ["{", "#"].include?(scanner.peek(1))
              self.curr_default_text += scanner.getch
            else
              # If the next token is a comment, trim trailing whitespace from
              # the text value so we don't add to the indentation of the next
              # value that is output after the comment
              self.curr_default_text = curr_default_text.gsub(/^\p{Blank}*\z/, "") if scanner.peek(1) == "#"
              tokens << [:TEXT, curr_default_text]
              self.curr_default_text = ""
              stack.pop
            end
          when :expression
            if scanner.scan(CLOSE_EXPRESSION)
              tokens << [:EXPRESSION_BODY, curr_expr]
              tokens << [:CLOSE_EXPRESSION]
              self.curr_expr = ""
              stack.pop
            elsif scanner.scan(OPEN_EXPRESSION)
              expression_inner_bracket
            elsif scanner.scan(DOUBLE_QUOTE)
              expression_inner_double_quote
            elsif scanner.scan(SINGLE_QUOTE)
              expression_inner_single_quote
            elsif scanner.scan(OPEN_TAG_DEF)
              potential_expression_inner_tag
            elsif expression_content?
              self.curr_expr += scanner.matched
            else
              raise SyntaxError, self
            end
          when :expression_inner_bracket
            if scanner.scan(CLOSE_EXPRESSION)
              self.curr_expr += scanner.matched
              stack.pop
            elsif scanner.scan(OPEN_EXPRESSION)
              expression_inner_bracket
            elsif scanner.scan(DOUBLE_QUOTE)
              expression_inner_double_quote
            elsif scanner.scan(SINGLE_QUOTE)
              expression_inner_single_quote
            elsif scanner.scan(OPEN_TAG_DEF)
              potential_expression_inner_tag
            elsif expression_content?
              self.curr_expr += scanner.matched
            else
              raise SyntaxError, self
            end
          when :expression_inner_double_quote
            if scanner.check(DOUBLE_QUOTE)
              expression_quoted_string_content
            elsif scanner.scan(DOUBLE_QUOTED_TEXT_CONTENT)
              self.curr_expr += scanner.matched
            else
              raise SyntaxError, self
            end
          when :expression_inner_single_quote
            if scanner.check(SINGLE_QUOTE)
              expression_quoted_string_content
            elsif scanner.scan(SINGLE_QUOTED_TEXT_CONTENT)
              self.curr_expr += scanner.matched
            else
              raise SyntaxError, self
            end
          when :tag_def
            if scanner.scan(CLOSE_SELF_CLOSING_TAG)
              tokens << [:CLOSE_TAG_DEF]
              tokens << [:OPEN_TAG_END]
              tokens << [:CLOSE_TAG_END]
              stack.pop(2)
            elsif scanner.scan(CLOSE_TAG)
              tokens << [:CLOSE_TAG_DEF]
              stack.pop
            elsif scanner.scan(TAG_NAME)
              tokens << [:TAG_DETAILS, tag_details(scanner.matched)]
            elsif scanner.scan(WHITESPACE)
              scanner.matched.count("\n").times { tokens << [:NEWLINE] }
              tokens << [:OPEN_ATTRS]
              stack.push(:tag_attrs)
            else
              raise SyntaxError, self
            end
          when :tag_end
            if scanner.scan(CLOSE_TAG)
              tokens << [:CLOSE_TAG_END]
              stack.pop(2)
            elsif scanner.scan(TAG_NAME)
              tokens << [:TAG_NAME, scanner.matched]
            else
              raise SyntaxError, self
            end
          when :tag_attrs
            if scanner.scan(WHITESPACE)
              scanner.matched.count("\n").times { tokens << [:NEWLINE] }
            elsif scanner.check(CLOSE_TAG)
              tokens << [:CLOSE_ATTRS]
              stack.pop
            elsif scanner.scan(ATTR_ASSIGNMENT)
              tokens << [:OPEN_ATTR_VALUE]
              stack.push(:tag_attr_value)
            elsif scanner.scan(ATTR)
              tokens << [:ATTR_NAME, scanner.matched.strip]
            elsif scanner.scan(OPEN_ATTR_SPLAT)
              tokens << [:OPEN_ATTR_SPLAT]
              tokens << [:OPEN_EXPRESSION]
              stack.push(:tag_attr_splat, :expression)
            else
              raise SyntaxError, self
            end
          when :tag_attr_value
            if scanner.scan(DOUBLE_QUOTE)
              stack.push(:quoted_text)
            elsif scanner.scan(OPEN_EXPRESSION)
              open_expression
            elsif scanner.scan(WHITESPACE) || scanner.check(CLOSE_TAG)
              tokens << [:CLOSE_ATTR_VALUE]
              scanner.matched.count("\n").times { tokens << [:NEWLINE] }
              stack.pop
            else
              raise SyntaxError, self
            end
          when :tag_attr_splat
            # Splat is consumed by :expression. It pops control back to here once
            # it's done, and we just record the completion and pop back to :tag_attrs
            tokens << [:CLOSE_ATTR_SPLAT]
            stack.pop
          when :quoted_text
            if scanner.scan(DOUBLE_QUOTED_TEXT_CONTENT)
              self.curr_quoted_text += scanner.matched
              self.curr_quoted_text += scanner.getch if scanner.matched.end_with?("\\") && scanner.peek(1) == "\""
            elsif scanner.scan(DOUBLE_QUOTE)
              tokens << [:TEXT, curr_quoted_text]
              self.curr_quoted_text = ""
              stack.pop
            else
              raise SyntaxError, self
            end
          else
            raise SyntaxError, self
          end
        end

        tokens
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      def potential_expression_inner_tag
        if curr_expr =~ EXPRESSION_INTERNAL_TAG_PREFIXES
          tokens << [:EXPRESSION_BODY, curr_expr]
          self.curr_expr = ""
          open_tag_def
        else
          self.curr_expr += scanner.matched
        end
      end

      def open_tag_def
        tokens << [:OPEN_TAG_DEF]
        stack.push(:tag, :tag_def)
      end

      def open_expression
        tokens << [:OPEN_EXPRESSION]
        stack.push(:expression)
      end

      def expression_inner_bracket
        self.curr_expr += scanner.matched
        stack.push(:expression_inner_bracket)
      end

      def expression_inner_double_quote
        self.curr_expr += scanner.matched
        stack.push(:expression_inner_double_quote)
      end

      def expression_inner_single_quote
        self.curr_expr += scanner.matched
        stack.push(:expression_inner_single_quote)
      end

      def expression_quoted_string_content
        self.curr_expr += scanner.getch
        stack.pop unless curr_expr.end_with?("\\")
      end

      def expression_content?
        # EXPRESSION_CONTENT ends at `<` characters, because we need to
        # separately scan for allowed open_tag_defs within expressions. We should
        # support any found open_tag_ends as expression content, as that means the
        # open_tag_def was not considered allowed (or stack would be inside
        # :tag_def instead of :expression) so we should thus also consider the
        # open_tag_end to just be a part of the expression (maybe its in a string,
        # etc).
        scanner.scan(EXPRESSION_CONTENT) || scanner.scan(OPEN_TAG_END)
      end

      def tag_details(name)
        type = element_resolver.component?(name) ? :component : :html
        details = { name: scanner.matched, type: type }
        details[:component_class] = element_resolver.component_class(name) if type == :component
        details
      end
    end
  end
end
