# frozen_string_literal: true

require "nextrb/component/options"

module Nextrb
  class OutputBuffer
    def initialize(buffer = "")
      @raw_buffer = String.new(buffer)
      @raw_buffer.encode!
    end

    def <<(value)
      unless value.nil?
        @raw_buffer << value.to_s # ERB::Util.unwrapped_html_escape(value)
      end
      self
    end
    alias concat <<

    def safe_concat(value)
      @raw_buffer << value
      self
    end

    def to_s
      @raw_buffer.to_s
    end
  end

  # Component is a single view handler
  class Component
    include Options

    class << self
      attr_accessor :compiled_template

      def inherited(subclass)
        super
        Nextrb::RBX.register_component(subclass)
        template_name = subclass.name.split("::").last
        class_filepath = Object.const_source_location(subclass.name.to_sym).first
        template_file_content = File.read(class_filepath)
        _, data = template_file_content.split(/^__END__$/, 2)
        return if data.nil?

        subclass.compiled_template = RBX.parse(resolve_template(template_name, data))
      end

      def resolve_template(name, data)
        return data unless data.include?("@@")

        templates = {}
        data.strip.split(/^(@@\s*.*\S)\s*$/)[1..].each_slice(2) do |(name, tmpl)|
          templates[name.delete_prefix("@@").strip] = tmpl
        end

        templates[name]
      end
    end

    def render
      @output_buffer = OutputBuffer.new
      instance_eval(self.class.compiled_template)
      @output_buffer.to_s
    end
  end
end
