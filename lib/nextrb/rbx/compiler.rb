# frozen_string_literal: true

module Nextrb
  module RBX
    # Compiler is a new version that does lexing and parsing all in one step
    class Compiler
      class SyntaxError < StandardError; end

      attr_reader :filename, :template, :resolver, :scanner

      HTML_VOID_ELEMENTS = %w[area base br col embed hr img input link meta source track wbr].freeze

      DECLR_OR_COMMENT = /\s*<![^>]*>/
      TAG_START = %r{\s*<(?!/)}
      TAG_END = %r{\s*/?>}
      TAG_CLOSE = %r{\s*</}
      EXPR_START = /\s*{/
      NOT_QUOTES = /[^"']+/
      QUOTED_STRING = /["'](?<str>(?:[^"'\\]|\\.)*)["']/
      QUOTES = /["']/
      PLAIN_TEXT = /(?<text>(?:[^<{\\]|\\.)*)/
      TAGNAME = /[A-Za-z0-9\-_.]+/
      DO_BLOCK_PREFIX = /do\s+(\|[^|]+\|)?/
      BLOCK_PREFIX = /{\s*(\|[^|]+\|)?/
      AND = /&&/
      OR = /\|\|/
      TERNARY = /[?:]/
      TAG_PREFIX = Regexp.union(DO_BLOCK_PREFIX, BLOCK_PREFIX, AND, OR, TERNARY)
      NESTED_TAG_PREFIX = /(\s+#{TAG_PREFIX.source}\s*\z|\A\s*\z)/
      WORD = /\w+/

      def initialize(filename, template, resolver = ComponentResolver.new)
        @filename = filename
        @template = template
        @resolver = resolver
        @scanner = StringScanner.new(template)
      end

      def parse
        parse_children
      end

      def parse_children
        parts = []
        until scanner.eos? || scanner.check(%r{</})
          parts << if scanner.scan(DECLR_OR_COMMENT) then Nodes::Raw.new(scanner.matched.gsub("'", "\\\\'"))
                   elsif scanner.scan(TAG_START) then parse_tag
                   elsif scanner.scan(EXPR_START) then parse_expression
                   elsif scanner.scan(PLAIN_TEXT) then Nodes::Raw.new(scanner[:text])
                   else raise SyntaxError
                   end
        end
        parts
      end

      def parse_tag
        tagname = scanner.scan(TAGNAME) # tagname
        node_klass = resolver.component?(tagname) ? Nodes::ComponentElement : Nodes::HTMLElement
        attr_klass = resolver.component?(tagname) ? Nodes::ComponentProp : Nodes::HTMLAttr
        node_klass.new(
          name: tagname,
          members: parse_tag_attributes(attr_klass),
          children: parse_contents(tagname)
        )
      end

      def parse_tag_attributes(attr_klass)
        attrs = []
        while scanner.check(/\s+[A-Za-z0-9\-_.:]+/) || scanner.check(EXPR_START)
          attrs << (scanner.scan(EXPR_START) ? parse_expression : parse_tag_attribute(attr_klass))
        end
        attrs
      end

      def parse_contents(tagname)
        raise SyntaxError, "malformed tag, no end found" unless scanner.scan(TAG_END)

        # allow void tags to not require using />
        is_void = scanner.matched.strip == "/>" || HTML_VOID_ELEMENTS.include?(tagname)
        children = is_void ? nil : parse_children
        unless is_void || scanner.scan(%r{\s*</#{tagname}>})
          raise SyntaxError,
                "Closing tag for #{tagname} not found"
        end

        children
      end

      def parse_tag_attribute(attr_klass)
        attr_name = scanner.scan(/\s+[A-Za-z0-9\-_.:]+/).strip
        value = scanner.scan(/\s*=\s*/) ? parse_tag_attribute_value : true # attribute without assignment
        attr_klass.new(attr_name, value)
      end

      def parse_tag_attribute_value
        if scanner.check(QUOTES) # parse string value stack.push(:quoted_text)
          chomp_quoted
        elsif scanner.scan(WORD) # plain values like value=yes or width=300
          scanner.matched
        elsif scanner.scan(EXPR_START) # start expression open_expression
          parse_expression
        else
          raise SyntaxError
        end
      end

      def parse_expression
        exprs = []

        open_count = 0
        close_count = 0
        curr_expr = String.new
        until scanner.eos?
          if scanner.scan(/}/)
            break unless close_count + curr_expr.count("}") < open_count + curr_expr.count("{")

            curr_expr += "}"
          elsif scanner.scan(TAG_START)
            # try to work out if we found a tag or a lessthan
            if curr_expr =~ NESTED_TAG_PREFIX
              open_count += curr_expr.count("{")
              close_count += curr_expr.count("}")
              exprs << Nodes::Expression.new(curr_expr) unless curr_expr.empty?
              curr_expr = String.new
              exprs << parse_tag
            else
              curr_expr += scanner.matched
            end
          else
            curr_expr += scanner.scan(/[^<}]+/)
          end
        end

        exprs << Nodes::Expression.new(curr_expr) unless curr_expr.empty?

        Nodes::ExpressionGroup.new(members: exprs)
      end

      def chomp_quoted(with_quotes: false)
        quote = scanner.check(QUOTES)
        scanner.scan(QUOTED_STRING)
        val = scanner[:str]
        raise SyntaxError, "unterminated string" if val.nil?

        with_quotes ? "#{quote}#{val}#{quote}" : val
      end

      def line_no
        template[0..scanner.pos].count("\n") + 1
      end
    end
  end
end
