# frozen_string_literal: true

require "strscan"

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
    # rubocop:disable Layout/LineLength
    TAG_START = %r{\s*<(?<tagname>[A-Za-z][A-Za-z0-9\-_.]*)(?<tag_attr>(?:"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|(?<attr_expr>\{(?:"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|[^\{\}"']|\g<attr_expr>)*\})|[^"'\{/>]|/(?!>))*)(?<close>/?>)}
    # rubocop:enable Layout/LineLength
    EXPR_START = /\s*{/
    QUOTED_STRING = /["'](?<str>(?:[^"'\\]|\\.)*)["']/
    QUOTES = /["']/
    QUOTED_EXPRESSION_STRING = /(?<q>["'])(?:\\.|(?!\k<q>).)*\k<q>/m
    PLAIN_TEXT = %r{(?<text>(?:[^<\{\\]|\\.|<(?![A-Za-z/!]))+)}
    DO_BLOCK_PREFIX = /do\s+(\|[^|]+\|)?/
    BLOCK_PREFIX = /{\s*(\|[^|]+\|)?/
    AND = /&&/
    OR = /\|\|/
    TERNARY = /[?:]/
    TAG_PREFIX = Regexp.union(DO_BLOCK_PREFIX, BLOCK_PREFIX, AND, OR, TERNARY)
    NESTED_TAG_PREFIX = /(\s+#{TAG_PREFIX.source}\s*\z|\A\s*\z)/
    WORD = /\w+/
    SCRIPT_TAG_CONTENTS = %r{(?<str>.*)</\s*script\s*>}

    private_constant :KNOWN_HTML_ELEMENTS, :HTML_VOID_ELEMENTS, :DECLR_OR_COMMENT,
                     :TAG_START, :EXPR_START, :QUOTED_STRING, :QUOTES,
                     :QUOTED_EXPRESSION_STRING, :PLAIN_TEXT, :DO_BLOCK_PREFIX,
                     :BLOCK_PREFIX, :AND, :OR, :TERNARY, :TAG_PREFIX, :NESTED_TAG_PREFIX,
                     :WORD, :SCRIPT_TAG_CONTENTS

    attr_reader :filename, :template, :scanner # :nodoc:

    # Is a struct for a single node in an AST type structure returned from the parser.
    # This struct consists of:
    #
    # - `kind`: raw, attribute, expression, expr_group, html, component
    # - `name`: If it is a component or html element this will be the tag name and
    #   the name of an element attribute if the node is an attribute.
    # - `attributes`: For tag, or components these are the attributes and their values.
    # - `content`: For tag, or components this will be any nested child nodes, for
    #   raw or expressions, this will be a string of raw output.
    # - `void`: marks if an element has nested content or expects nested content.
    Node = Struct.new(:kind, :name, :attributes, :content, :void)

    # Reads a template, lexes tokens, and builds an AST from the tokens.
    def self.parse(filename, template)
      new(filename, template).parse
    end

    def initialize(filename, template) # :nodoc:
      @filename = filename
      @template = template
      @scanner = StringScanner.new(template)
    end

    def parse = parse_children # :nodoc:

    private

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
      tagname = scanner[:tagname]
      is_void = scanner[:close] == "/>" || HTML_VOID_ELEMENTS.include?(tagname)
      attributes = parse_tag_attributes(scanner[:tag_attr])
      children = is_void ? nil : parse_tag_contents(tagname, is_void)
      Node.new(kind: resolve_kind(tagname), name: tagname, void: is_void, attributes: attributes, content: children)
    end

    def parse_tag_contents(tagname, is_void)
      return consume_script_tag_raw if tagname == "script" && !is_void

      children = parse_children
      if !is_void && !scanner.scan(%r{\s*</\s*#{tagname}\s*>})
        raise SyntaxError.new(self, "Closing tag for non-void <#{tagname}> not found")
      end

      children
    end

    # We consume script tag contents simply as a raw node because we cannot interpolate
    # anything in javascript. We cannot tell what {} are javascript and which are
    # interpolation so it is safer to just leave script contents alone.
    def consume_script_tag_raw
      scanner.scan(SCRIPT_TAG_CONTENTS)
      val = scanner[:str]
      raise SyntaxError.new(self, "unterminated script tag") if val.nil?

      [Node.new(kind: :raw, content: val)]
    end

    def resolve_kind(tagname)
      return :html if KNOWN_HTML_ELEMENTS.include?(tagname)

      klass_name = "::#{tagname.split(".").join("::")}"
      klass = Object.const_get(klass_name)
      !klass.nil? && klass.include?(RBX::Component) ? :component : :html
    end

    def parse_tag_attributes(tag_attrs)
      attrs = []
      attr_scanner = StringScanner.new(tag_attrs.strip)
      until attr_scanner.eos?
        attrs << if attr_scanner.scan(EXPR_START)
                   parse_expression(scanner: attr_scanner)
                 else
                   parse_tag_attribute(attr_scanner)
                 end
      end
      attrs.empty? ? nil : attrs
    end

    def parse_tag_attribute(attr_scanner)
      Node.new(
        kind: :attribute,
        name: attr_scanner.scan(/\s*[A-Za-z0-9\-_.:]+/).strip,
        content: parse_tag_attribute_value(attr_scanner)
      )
    end

    def parse_tag_attribute_value(attr_scanner)
      return nil unless attr_scanner.scan(/\s*=\s*/)

      if attr_scanner.check(QUOTES) then Node.new(kind: :raw, content: chomp_quoted(attr_scanner))
      elsif attr_scanner.scan(WORD) then Node.new(kind: :raw, content: attr_scanner.matched)
      elsif attr_scanner.scan(EXPR_START) then parse_expression(scanner: attr_scanner)
      else raise SyntaxError.new(self, "unexpected tag attribute formatting.")
      end
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def parse_expression(scanner: self.scanner)
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

    def chomp_quoted(attr_scanner)
      attr_scanner.scan(QUOTED_STRING)
      val = attr_scanner[:str]
      raise SyntaxError.new(self, "unterminated quoted string") if val.nil?

      %("#{val}")
    end
  end
end
