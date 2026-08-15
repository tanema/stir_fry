# frozen_string_literal: true

module Nextrb
  module RBX
    # Nodes is the namespace that contains all the different types of nodes parsed
    # from the html.
    module Nodes
      OUTPUT_EXPR = "_nextrbout << Array(%s).join\n"
      OUTPUT_RAW = "_nextrbout << '%s'\n"
      RAW = "%s"
      EXPR_STRING = "'%s'"

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
