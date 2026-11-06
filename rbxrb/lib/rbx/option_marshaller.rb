# frozen_string_literal: true

require "json"
require "rack"

module RBX
  # OptionMarshaller is a class that is used for serializing a hash into
  # html tag attributes.
  class OptionMarshaller
    BOOLEAN_ATTRIBUTES = %w[allowfullscreen allowpaymentrequest async autofocus
                            autoplay checked compact controls declare default
                            defaultchecked defaultmuted defaultselected defer
                            disabled enabled formnovalidate hidden indeterminate
                            inert ismap itemscope loop multiple muted nohref
                            nomodule noresize noshade novalidate nowrap open
                            pauseonexit playsinline readonly required reversed
                            scoped seamless selected sortable truespeed
                            typemustmatch visible].to_set

    BOOLEAN_ATTRIBUTES.merge(BOOLEAN_ATTRIBUTES.map(&:to_sym))
    BOOLEAN_ATTRIBUTES.freeze

    private_constant :BOOLEAN_ATTRIBUTES

    class << self
      ##
      # Marshal a hash into html tag attributes. If the key is aria, data, or class
      # it will also spread that data creatively like `data-key="true"` from `{data: {key: true}}`
      # and for class it will only include the class name if the value is truthy.
      def tag_kwargs(options)
        options.reject { |k, _v| k.empty? }.map do |key, value|
          case key.to_s
          when "aria", "data", "hx" then value.map { |k, v| tag_option("#{key}-#{k}", v) }
          when "class" then tag_option("class", class_value(value))
          else tag_option(key, value)
          end
        end.flatten.compact.join(" ")
      end

      private

      def class_value(value)
        case value
        when Hash then value.select { |_k, v| v }.keys
        when Array then value
        else [value.to_s]
        end.join(" ")
      end

      def tag_option(key, value)
        key = key.to_s.tr("_", "-")
        return value ? key : "" if BOOLEAN_ATTRIBUTES.include?(key)

        case value
        when Array, Hash then %(#{key}="#{Rack::Utils.escape_html(JSON.dump(value))}")
        when TrueClass then key
        when FalseClass then ""
        when Integer then %(#{key}=#{value})
        else %(#{key}="#{Rack::Utils.escape_html(value.to_s)}")
        end
      end
    end
  end
end
