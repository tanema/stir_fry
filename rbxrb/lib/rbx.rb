# frozen_string_literal: true

require "rack"

# RBX is a module for handling enriched html parsing in a same manner that jsx does
# allowing for class resolution for tag names and dynamic content taken from those
# ruby classes.
#
# Example:
#
# ```ruby
# module Todos
#   class List
#     include RBX::Component
#
#     attr_reader :todos
#
#     def initialize(todos:)
#       super()
#       @todos = todos
#     end
#   end
#
#   class Todo
#     include RBX::Component
#     attr_reader :todo
#
#     def initialize(todo:)
#       super()
#       @todo = todo
#     end
#   end
# end
#
# view = Todos::List.new(todos: [{"text" => "work"}])
# puts view.render # => <ul><li>work</li> </ul>
#
# __END__
# @@Todos.List
# <ul>{todos.map { |todo| <Todos.Todo todo={todo} /> }.join}</ul>
#
# @@Todos.Todo
# <li>{ todo["text"] }</li>
# ```
#
# Component templates can be defined in several ways.
#
# - With the entirety of the `__END__` section if it does not contain any labels.
# - Several templates defined for several classes in the same file (like the example above).
#   To do this the templates need a `@@<klass-name>` label to identify them.
# - Use the component class method `template_file` to define where to look for the
#   template file.
# - Use the component class method `template_source` to provide a raw string as a
#   template for the component.
#
module RBX
  autoload :Compiler, "rbx/compiler"
  autoload :Parser, "rbx/parser"
  autoload :SyntaxError, "rbx/syntax_error"
  autoload :Component, "rbx/component"
  autoload :OptionMarshaller, "rbx/option_marshaller"
  autoload :VERSION, "rbx/version"

  # SafeString is a string wrapper that marks a string as having been escaped and
  # is safe for putting on a webpage.
  class SafeString < String; end

  @template_cache = {}

  class << self
    # parse and then compile the template which will return a string of ruby to
    # be evaluated. This can then be passed to `instance_eval` to make it execute
    # in context of your class. Include `RBX::Component` in your class to do this
    # for you. It will lazily compile the template and cache it afterwards.
    def compile(template_name, template)
      Compiler.compile(Parser.parse(template_name, template))
    end

    # escape any non-safe text for html. This is used to ensure that text that
    # you are using in your templates will not cause security issues. This will
    # be outputted by the compiler so it is here also for easy access by the compiled
    # ruby.
    def escape(value)
      value.is_a?(SafeString) ? value.to_s : ::Rack::Utils.escape_html(value.to_s)
    end

    # mark a string as safe, not needing any further escaping. This can be done to
    # skip escaping if you're sure it needs to be raw.
    def safe(value)
      SafeString.new(value.to_s)
    end

    # marshal a hash into html tag attributes. See OptionMarshaller.
    def tag_kwargs(options)
      " #{OptionMarshaller.tag_kwargs(options)}"
    end

    # resolve an inline template for a klass. It will look at the klass's source
    # location, and check if there is an `__END__` section on the file. If there
    # is, it will extract that template data.
    #
    # A template can be the whole `__END__` section if there are no labels found
    # or several templates can be defined in the `__END__` section by labeling them
    # with an `@@<name>` label on the line before the template. See the example above.
    def resolve_template(klass)
      location = Object.const_source_location(klass.name).first
      extract_template(location, klass, inline: true)
    end

    # depending on how the template is defined, extract_template will look in the
    # `__END__` section, determine if there are several templates, and pick out
    # the template for the specific class passed as a parameter. It will return
    # an empty string if no content was found.
    #
    # This will also ensure that templates were not reused just incase labels were
    # not added.
    def extract_template(filepath, klass, inline: true)
      name = klass.name.split("::").last
      fullname = template_name(filepath, name)
      parse_templates(filepath, name, inline) unless @template_cache[fullname]
      tmpl = @template_cache.fetch(fullname, nil)
      validate_uniq_templates(filepath, tmpl[:content]) if tmpl

      [fullname, tmpl&.dig(:content) || ""]
    end

    private

    def validate_uniq_templates(filepath, content)
      found = @template_cache.values.select { |tmpl| tmpl[:filepath] == filepath && tmpl[:content] == content }
      return unless found.count > 1

      warn "[RBX WARNING] Possible reuse of template #{template_name(found[:filepath], found[:name])}"
    end

    def template_name(filepath, name)
      "#{filepath}@@#{name}"
    end

    def parse_templates(filepath, name, inline)
      data = read_file(filepath, inline)
      return if data.nil?

      cache_template(filepath, name, data)
      return unless data.include?("@@")

      data.strip.split(/^(@@\s*.*\S)\s*$/)[1..].each_slice(2) do |(section_name, tmpl)|
        section_name = section_name.delete_prefix("@@").strip
        cache_template(filepath, section_name, tmpl)
      end
    end

    def cache_template(filepath, name, content)
      @template_cache[template_name(filepath, name)] = {
        filepath: filepath,
        name: name,
        content: content
      }
    end

    def read_file(filepath, inline)
      data = File.read(filepath)
      return if inline && !data.include?("__END__")

      data = data.split(/^__END__$/, 2)[1] if data.include?("__END__")
      data
    end
  end
end
