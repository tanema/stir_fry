# frozen_string_literal: true

module Nextrb
  module RBX
    # Nodes is the namespace that contains all the different types of nodes parsed
    # from the html.
    module Nodes
      OUTPUT_EXPR = "@output_buffer.concat(%s);\n"
      OUTPUT_RAW = "@output_buffer.safe_concat('%s');\n"
      EXPR_STRING = "'%s'"
      RAW = "%s"

      autoload :Base, "nextrb/rbx/nodes/base"
      autoload :ComponentElement, "nextrb/rbx/nodes/component_element"
      autoload :ComponentProp, "nextrb/rbx/nodes/component_prop"
      autoload :Expression, "nextrb/rbx/nodes/expression"
      autoload :ExpressionGroup, "nextrb/rbx/nodes/expression_group"
      autoload :HTMLAttr, "nextrb/rbx/nodes/html_attr"
      autoload :HTMLElement, "nextrb/rbx/nodes/html_element"
      autoload :Raw, "nextrb/rbx/nodes/raw"
      autoload :Root, "nextrb/rbx/nodes/root"
    end
  end
end
