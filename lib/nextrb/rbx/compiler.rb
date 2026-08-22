# frozen_string_literal: true

module Nextrb
  module RBX
    # Compiler takes in the parsed AST and outputs generated code.
    class Compiler
      def self.compile(nodes)
        new.compile(nodes)
      end

      def compile(nodes)
        <<~RBX
          buffer = String.new
          #{nodes.map { |n| buf_out(compile_node(n)) }.join.rstrip}
          buffer
        RBX
      end

      def compile_node(node)
        case node.kind
        when :raw then node.content.strip.empty? ? "" : "'#{escape(node.content)}'"
        when :html then compile_html(node).join("+")
        when :component then compile_component(node)
        when :expr_group then compile_text_expr_group(node)
        else raise "unexpected node kind #{node.kind}"
        end
      end

      def compile_text_expr_group(node)
        return "(#{compile_expr_group(node)}).to_s" if contains_markup?(node)

        "::Nextrb::RBX.escape((#{compile_expr_group(node)}))"
      end

      def contains_markup?(node)
        node.content&.any? { |n| %i[html component].include?(n.kind) }
      end

      def compile_html(node)
        parts = tag_open(node)
        parts.concat(node.content.map(&method(:compile_node))) unless node.void || node.content.nil?
        parts << "'</#{node.name}>'" unless node.void
        compact(parts)
      end

      def tag_open(node)
        buffer = "<#{node.name}"
        parts = []
        node.attributes&.each { |attr| tag_attribute(buffer, parts, attr) }
        buffer << (node.void ? "/>" : ">")
        parts << "'#{escape(buffer)}'"
        parts
      end

      def tag_attribute(buffer, parts, attr)
        return kwarg_attribute(buffer, parts, attr) if attr.kind == :expr_group

        buffer << " #{attr.name}"
        return if attr.content.nil?

        buffer << "="
        case attr.content.kind
        when :raw then buffer << attr.content.content
        when :expr_group then tag_attribute_expression(buffer, parts, attr.content)
        else raise "unexpected attribute value kind #{attr.content.kind}"
        end
      end

      def tag_attribute_expression(buffer, parts, expr_group)
        buffer << '"'
        flush_buffer(buffer, parts)
        parts << "::Nextrb::RBX.escape((#{compile_attr_expr_group(expr_group)}))"
        buffer << '"'
      end

      def kwarg_attribute(buffer, parts, expr_group)
        flush_buffer(buffer, parts)
        parts << "(tag_kwargs(#{compile_attr_expr_group(expr_group)})).to_s"
      end

      def flush_buffer(buffer, parts)
        parts << "'#{escape(buffer)}'" unless buffer.empty?
        buffer.replace("")
      end

      def compile_component(node)
        "::#{node.name.split(".").join("::")}.new(#{component_props(node)})#{component_block(node)}.render"
      end

      def component_props(node)
        node.attributes&.map { |attr| component_prop(attr) }&.join(", ")
      end

      def component_prop(attr)
        return "#{attr.name}: true" if attr.content.nil?

        "#{attr.name}: #{component_prop_value(attr.content)}"
      end

      def component_prop_value(expr)
        case expr.kind
        when :raw then expr.content
        when :expr_group then "(#{compile_attr_expr_group(expr)})"
        else raise "unexpected component prop kind #{expr.kind}"
        end
      end

      def compile_attr_expr_group(node)
        node.content&.map do |n|
          case n.kind
          when :raw, :expression then n.content
          else raise "unexpected component prop kind #{n.kind}"
          end
        end&.join
      end

      def compile_expr_group(node)
        node.content&.map do |n|
          case n.kind
          when :raw, :expression then n.content
          when :html then "(#{compile_html(n).join("+")})"
          when :component then "(#{compile_component(n)})"
          else raise "unexpected component prop kind #{n.kind}"
          end
        end&.join
      end

      def component_block(node)
        return "" if node.content.nil? || node.content.empty?

        <<~RBX.strip
          .capture do |buffer|
            #{node.content.map { |n| buf_out(compile_node(n)) }.join.rstrip}
          end
        RBX
      end

      def buf_out(content)
        content.strip.empty? ? "" : %(buffer << #{content}\n)
      end

      def escape(str)
        str.gsub("\\") { "\\\\" }.gsub("'") { "\\'" }
      end

      def compact(parts)
        parts&.each_with_object([]) do |item, compacted|
          next if item.empty?

          if quoted_string?(item) && quoted_string?(compacted.last)
            compacted[-1] = compacted.last.delete_suffix("'") + item.delete_prefix("'")
          else
            compacted.push(item)
          end
        end
      end

      def quoted_string?(item)
        item =~ /^'.*'$/
      end
    end
  end
end
