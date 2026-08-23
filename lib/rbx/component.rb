# frozen_string_literal: true

module RBX
  # Component is a mixin that lazily resolves and compiles a template into a
  # `_render_template` instance method on the first render, then calls that
  # compiled method directly on every render after that. It also provides
  # the supporting capture/option marshalling behavior compiled templates
  # rely on.
  module Component
    def self.included(base)
      base.extend(ClassMethods)
    end

    # ClassMethods is extended onto any class that includes Component. It
    # handles template resolution and compilation.
    module ClassMethods
      attr_reader :template, :template_location, :compiled_template

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

      protected

      # Compile will take in a location for error messages and string template
      # and compile it as RBX, then define the `_render_template` instance
      # method that `render` calls directly on every render after the first.
      def compile!(loc, tmpl)
        @template_location = loc
        @template = tmpl
        return if @template_location.nil? || @template.empty?

        @compiled_template = RBX.compile(@template_location, @template)

        class_eval(<<~RENDER, __FILE__, __LINE__ + 1)
          def _render_template
            #{@compiled_template} # compiled template body
          end
        RENDER
      end
    end

    # On the first call, resolves and compiles this class's template (unless
    # template_source/template_file already did so), which defines
    # _render_template. Every subsequent call skips straight to it.
    def render
      klass = self.class
      klass.send(:compile!, *RBX.resolve_template(klass)) if klass.template_location.nil?

      _render_template { RBX.safe(@child_buffer.nil? ? "" : @child_buffer) }
    end

    def capture(&)
      @child_buffer = String.new
      yield(@child_buffer)
      self
    end

    def tag_kwargs(options)
      " #{OptionMarshaller.tag_kwargs(options)}"
    end
  end
end
