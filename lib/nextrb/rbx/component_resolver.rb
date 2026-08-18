# frozen_string_literal: true

module Nextrb
  module RBX
    # ComponentResolver is a registry that contains custom components that may be
    # embedded in the html. It will resolve the name to the class that has been defined.
    class ComponentResolver
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

      attr_reader :components

      def initialize
        @components = {}
      end

      def register(klass)
        components[classname_to_tagname(klass.name)] = klass
      end

      def component?(name)
        !KNOWN_HTML_ELEMENTS.include?(name) && component_class(name)
      end

      def component_class(name)
        load_const(name) unless components[name]
        components[name]
      end

      def classname_to_tagname(name)
        name.split("::").join(".")
      end

      def tagname_to_classname(name)
        "::#{name.split(".").join("::")}"
      end

      def load_const(name)
        Object.const_get(tagname_to_classname(name))
      rescue StandardError
        nil
      end
    end
  end
end
