# frozen_string_literal: true

require "rack"

module Nextrb
  # RBX is a module for handling enriched html parsing in a same manner that jsx does
  module RBX
    autoload :Compiler, "nextrb/rbx/compiler"
    autoload :Parser, "nextrb/rbx/parser"
    autoload :SyntaxError, "nextrb/rbx/syntax_error"

    # SafeString marks a string as already-rendered HTML that must not be escaped again.
    class SafeString < String; end

    @template_cache = {}

    class << self
      def compile(template_name, template)
        Compiler.compile(Parser.parse(template_name, template))
      end

      # Escapes a value for safe HTML output, unless it is already marked as
      # rendered HTML via SafeString (e.g. captured child content from yield).
      def escape(value)
        value.is_a?(SafeString) ? value.to_s : ::Rack::Utils.escape_html(value.to_s)
      end

      def safe(value)
        SafeString.new(value.to_s)
      end

      def resolve_template(klass)
        location = Object.const_source_location(klass.name).first
        extract_template(location, klass, inline: true)
      end

      def extract_template(filepath, klass, inline: true)
        name = klass.name.split("::").last
        fullname = template_name(filepath, name)
        parse_templates(filepath, name, inline) unless @template_cache[fullname]
        tmpl = @template_cache.fetch(fullname) { warn "[NEXTRB WARNING] no #{fullname} template found" }
        validate_uniq_templates(filepath, tmpl[:content]) if tmpl

        [fullname, tmpl&.dig(:content) || ""]
      end

      private

      def validate_uniq_templates(filepath, content)
        found = @template_cache.values.select { |tmpl| tmpl[:filepath] == filepath && tmpl[:content] == content }
        return unless found.count > 1

        warn "[NEXTRB WARNING] Possible reuse of template #{template_name(found[:filepath], found[:name])}"
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
end
