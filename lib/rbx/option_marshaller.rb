# frozen_string_literal: true

require "json"
require "rack"

module RBX
  # OptionMarshaller is a class that is used for serializing a hash into
  # html tag attributes. It is a class so that scope of methods can be managed.
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

    class << self
      def tag_kwargs(options)
        options.reject { |k, _v| k.empty? }.map do |key, value|
          case key.to_s
          when "aria" then aria_attribute(value)
          when "data" then data_attribute(value)
          when "class" then class_attribute(value)
          when "hx" then hx_attribute(value)
          else boolean_or_option(key, value)
          end
        end.flatten.compact.join(" ")
      end

      private

      def boolean_or_option(key, value)
        BOOLEAN_ATTRIBUTES.include?(key) ? (key if value) : tag_option(key, value)
      end

      def aria_attribute(value)
        value.map { |k, v| %(aria-#{k}="#{Rack::Utils.escape_html(v.to_s)}") }
      end

      def data_attribute(value)
        value.map do |k, v|
          tag_option("data-#{k}", v.is_a?(String) || v.is_a?(Symbol) ? v : JSON.dump(v))
        end
      end

      def hx_attribute(value)
        value.map { |k, v| tag_option("hx-#{k}", v.to_s) }
      end

      def class_attribute(value)
        classes = if value.is_a?(Hash)
                    value.each_with_object([]) { |(key, value), final| final << key if value }.join(" ")
                  else
                    value.is_a?(Array) ? value.join(" ") : value.to_s
                  end
        %(class="#{Rack::Utils.escape_html(classes)}")
      end

      def tag_option(key, value)
        value = case value
                when Array then value.join(" ")
                when Hash then value.map { |k, v| "#{k}=#{v}" }.join(" ")
                else value.to_s
                end
        %(#{key.to_s.tr("_", "-")}="#{Rack::Utils.escape_html(value)}")
      end
    end
  end
end
