module Nextrb
  module RBX
    module Nodes
      autoload :AbstractNode, "nextrb/rbx/nodes/abstract_node"
      autoload :Root, "nextrb/rbx/nodes/root"
      autoload :Raw, "nextrb/rbx/nodes/raw"
      autoload :Text, "nextrb/rbx/nodes/text"
      autoload :ExpressionGroup, "nextrb/rbx/nodes/expression_group"
      autoload :Expression, "nextrb/rbx/nodes/expression"
      autoload :AbstractElement, "nextrb/rbx/nodes/abstract_element"
      autoload :HTMLElement, "nextrb/rbx/nodes/html_element"
      autoload :ComponentElement, "nextrb/rbx/nodes/component_element"
      autoload :AbstractAttr, "nextrb/rbx/nodes/abstract_attr"
      autoload :HTMLAttr, "nextrb/rbx/nodes/html_attr"
      autoload :ComponentProp, "nextrb/rbx/nodes/component_prop"
      autoload :Newline, "nextrb/rbx/nodes/newline"
      autoload :Declaration, "nextrb/rbx/nodes/declaration"
    end
  end
end
