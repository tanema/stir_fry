# frozen_string_literal: true

module Nextrb
  module RBX
    # Parser breaks down templates into a tree like data structure
    class Parser
      KNOWN_HTML_ELEMENTS = %w[
        a abbr acronym address animate animateMotion animateTransform applet area article aside audio b base basefont
        bdi bdo bgsound big blink blockquote body br button canvas caption center circle cite clipPath code col colgroup
        color-profile command content data datalist dd defs del desc details dfn dialog dir discard div dl dt element
        ellipse em embed feBlend feColorMatrix feComponentTransfer feComposite feConvolveMatrix feDiffuseLighting
        feDisplacementMap feDistantLight feDropShadow feFlood feFuncA feFuncB feFuncG feFuncR feGaussianBlur feImage
        feMerge feMergeNode feMorphology feOffset fePointLight feSpecularLighting feSpotLight feTile feTurbulence
        fieldset figcaption figure filter font footer foreignObject form frame frameset g h1 h2 h3 h4 h5 h6 hatch
        hatchpath head header hgroup hr html i iframe image img input ins isindex kbd keygen label legend li line
        linearGradient link listing main map mark marker marquee mask menu menuitem mesh meshgradient meshpatch meshrow
        meta metadata meter mpath multicol nav nextid nobr noembed noframes noscript object ol optgroup option output p
        param path pattern picture plaintext polygon polyline pre progress q radialGradient rb rect rp rt rtc ruby s
        samp script section select set shadow slot small solidcolor source spacer span stop strike strong style sub
        summary sup svg switch symbol table tbody td template text textarea textPath tfoot th thead time title tr track
        tspan tt u ul unknown use var video view wbr xmp
      ].to_set

      HTML_VOID_ELEMENTS = %w[area base br col embed hr img input link meta source track wbr].freeze
      DECLR_OR_COMMENT = /\s*<![^>]*>/
      TAG_START = %r{\s*<(?!/)}
      TAG_END = %r{\s*/?>}
      EXPR_START = /\s*{/
      QUOTED_STRING = /["'](?<str>(?:[^"'\\]|\\.)*)["']/
      QUOTES = /["']/
      QUOTED_EXPRESSION_STRING = /(?<q>["'])(?:\\.|(?!\k<q>).)*\k<q>/m
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

      attr_reader :filename, :template, :scanner

      Node = Struct.new(:kind, :name, :attributes, :content, :void)

      def self.parse(filename, template)
        new(filename, template).parse
      end

      def initialize(filename, template)
        @filename = filename
        @template = template
        @scanner = StringScanner.new(template)
      end

      def parse
        parse_children
      end

      def parse_children
        children = []
        children << parse_child until scanner.eos? || scanner.check(%r{</})
        children.empty? ? nil : children
      end

      def parse_child
        if scanner.scan(DECLR_OR_COMMENT) then Node.new(kind: :raw, content: scanner.matched.gsub("'", "\\\\'"))
        elsif scanner.scan(TAG_START) then parse_tag
        elsif scanner.scan(EXPR_START) then parse_expression
        elsif scanner.scan(PLAIN_TEXT) then Node.new(kind: :raw, content: scanner[:text])
        else raise SyntaxError.new(self, "unexpected element")
        end
      end

      def parse_tag
        tagname = scanner.scan(TAGNAME) # tagname
        attributes = parse_tag_attributes
        raise SyntaxError.new(self, "unclosed tag <#{tagname} found") unless scanner.scan(TAG_END)

        is_void = scanner.matched.strip == "/>" || HTML_VOID_ELEMENTS.include?(tagname)
        children = is_void ? nil : parse_children
        if !is_void && !scanner.scan(%r{\s*</#{tagname}>})
          raise SyntaxError.new(self, "Closing tag for non-void <#{tagname}> not found")
        end

        Node.new(kind: resolve_kind(tagname), name: tagname, void: is_void, attributes: attributes, content: children)
      end

      def resolve_kind(tagname)
        return :html if KNOWN_HTML_ELEMENTS.include?(tagname)

        klass_name = "::#{tagname.split(".").join("::")}"
        klass = Object.const_get(klass_name)
        # TODO: allow duck typing, i.e responds_to
        !klass.nil? && klass < ::Nextrb::Component ? :component : :html
      end

      def parse_tag_attributes
        attrs = []
        while scanner.check(/\s+[A-Za-z0-9\-_.:]+/) || scanner.check(EXPR_START)
          attrs << (scanner.scan(EXPR_START) ? parse_expression : parse_tag_attribute)
        end
        attrs.empty? ? nil : attrs
      end

      def parse_tag_attribute
        name = scanner.scan(/\s+[A-Za-z0-9\-_.:]+/).strip
        value = parse_tag_attribute_value if scanner.scan(/\s*=\s*/)
        Node.new(kind: :attribute, name: name, content: value)
      end

      def parse_tag_attribute_value
        if scanner.check(QUOTES) then Node.new(kind: :raw, content: chomp_quoted)
        elsif scanner.scan(WORD) then Node.new(kind: :raw, content: scanner.matched)
        elsif scanner.scan(EXPR_START) then parse_expression
        else raise SyntaxError.new(self, "unexpected tag attribute formatting.")
        end
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def parse_expression
        exprs = []

        depth = 0
        curr_expr = String.new
        until scanner.eos?
          if scanner.scan(/}/)
            break if depth.zero?

            depth -= 1
            curr_expr << "}"
          elsif scanner.scan(QUOTED_EXPRESSION_STRING)
            curr_expr << scanner.matched
          elsif scanner.scan(TAG_START)
            # try to work out if we found a tag or a lessthan
            if curr_expr =~ NESTED_TAG_PREFIX
              exprs << Node.new(kind: :expression, content: curr_expr) unless curr_expr.empty?
              curr_expr = String.new
              exprs << parse_tag
            else
              curr_expr << scanner.matched
            end
          else
            text = scanner.scan(/([^<}'"]|<\/)+/) || scanner.getch
            depth += text.count("{")
            curr_expr << text
          end
        end

        exprs << Node.new(kind: :expression, content: curr_expr) unless curr_expr.empty?

        Node.new(kind: :expr_group, content: exprs)
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      def chomp_quoted
        scanner.scan(QUOTED_STRING)
        val = scanner[:str]
        raise SyntaxError.new(self, "unterminated string") if val.nil?

        %("#{val}")
      end
    end
  end
end
