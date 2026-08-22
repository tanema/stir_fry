# frozen_string_literal: true

module Nextrb
  # Component is a single view handler
  class Component
    class << self
      attr_reader :template, :template_location, :compiled_template

      # On inheriting this class, it will resolve an inline template if available.
      # If not, the developer can call template_source or template_file to provide
      # it in the future.
      def inherited(subclass)
        super
        loc, tmpl = RBX.resolve_template(subclass)
        subclass.compile!(loc, tmpl)
      end

      # Set the template for this class as a provided string. This method uses
      # caller location to be able to provide better error messages.
      def template_source(tmpl)
        compile!(caller_locations(1, 1).first.absolute_path, tmpl)
      end

      # Set the template for this class as the contents of a separate file
      def template_file(filepath)
        loc, tmpl = RBX.extract_template(filepath, self, inline: false)
        compile!(loc, tmpl)
      end

      def call(req, resp, **args)
        new(**args).call(req, resp)
      end

      protected

      # Compile will take in a location for error messages and string template
      # and compile it as RBX, then set the compiled_template attr on the class
      # to be used for all render calls.
      def compile!(loc, tmpl)
        @template_location = loc
        @template = tmpl
        return if @template_location.nil? || @template.empty?

        @compiled_template = RBX.compile(@template_location, @template)
      end
    end

    attr_reader :request, :response

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
      _render_with_block { RBX.safe(@child_buffer.nil? ? "" : @child_buffer) }
    end

    def tag_kwargs(options)
      " #{OptionMarshaller.tag_kwargs(options)}"
    end

    private

    def _render_with_block
      instance_eval(self.class.compiled_template)
    end
  end
end
