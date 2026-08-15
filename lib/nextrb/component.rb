# frozen_string_literal: true

require "nextrb/components/options"

module Nextrb
  # Component is a single view handler
  class Component
    include Components::Options

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
        data.strip.split(/^(@@\s*.*\S)\s*$/)[1..].each_slice(2) do |(section_name, tmpl)|
          templates[section_name.delete_prefix("@@").strip] = tmpl
        end

        templates.fetch(name) { raise "no @@#{name} template section found" }
      end
    end

    def call
      response = Rack::Response.new
      response.status = Rack::Utils.status_code(:ok)
      response["Content-Type"] = "text/html"
      response.body = [render]
      response.to_a
    end

    def capture(&)
      @child_buffer = String.new
      yield(@child_buffer)
      self
    end

    def render
      _render_with_block { @child_buffer.nil? ? "" : @child_buffer }
    end

    def _nextrbout
      @_nextrbout ||= String.new
    end

    def reset!
      @_nextrbout = nil
    end

    private

    def _render_with_block
      reset!
      instance_eval(self.class.compiled_template)
      _nextrbout
    end
  end
end
