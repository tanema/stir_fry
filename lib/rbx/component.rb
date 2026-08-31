# frozen_string_literal: true

module RBX
  # Component is a mixin that lazily resolves and compiles a template into a
  # `_render_template` instance method on the first render, then calls that
  # compiled method directly on every render after that. It also provides
  # the supporting capture/option marshalling behavior compiled templates
  # rely on.
  module Component
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
    end

    # ClassMethods is extended onto any class that includes Component. It
    # handles template resolution and compilation.
    module ClassMethods
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

      def compile!(loc, tmpl) # :nodoc:
        return if loc.nil? || tmpl.empty?

        class_eval(<<~RENDER, __FILE__, __LINE__ + 1)
          def _render_template
            #{RBX.compile(loc, tmpl)} # compiled template body
          end
        RENDER
      end
    end

    # render will lazily compile the template for this class and then render it using
    # the class as context as the compilation will define a _render_template method
    # on the instance.
    def render
      klass = self.class
      klass.send(:compile!, *RBX.resolve_template(klass)) unless klass.respond_to?(:_render_template)

      _render_template { RBX.safe(@child_buffer.nil? ? "" : @child_buffer) }
    end

    # public method to capture child content but should not be considered public interface.
    def capture(&) # :nodoc:
      @child_buffer = String.new
      yield(@child_buffer)
      self
    end
  end
end
