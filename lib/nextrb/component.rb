# frozen_string_literal: true

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
        class_filepath = Object.const_source_location(subclass.name).first
        template_file_content = File.read(class_filepath)
        _, data = template_file_content.split(/^__END__$/, 2)
        return if data.nil?

        subclass.compiled_template = RBX.parse(
          "#{class_filepath}@@#{template_name}",
          resolve_template(template_name, data)
        )
      end

      def resolve_template(name, data)
        return data unless data.include?("@@")

        templates = {}
        data.strip.split(/^(@@\s*.*\S)\s*$/)[1..].each_slice(2) do |(section_name, tmpl)|
          templates[section_name.delete_prefix("@@").strip] = tmpl
        end

        templates.fetch(name) { raise "no @@#{name} template section found" }
      end

      def call(req, resp, **args)
        new(**args).call(req, resp)
      end
    end

    attr_reader :request, :response, :_nextrbout

    def call(request, response)
      @request = request
      @response = response
      response.html(render)
    end

    def capture(&)
      @child_buffer = String.new
      yield(@child_buffer)
      self
    end

    def render
      _render_with_block { @child_buffer.nil? ? "" : @child_buffer }
    end

    private

    def _render_with_block
      @_nextrbout = String.new
      instance_eval(self.class.compiled_template)
      _nextrbout
    end
  end
end
