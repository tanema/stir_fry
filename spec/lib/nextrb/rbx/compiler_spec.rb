# frozen_string_literal: true

class TestResolver
  def component?(name)
    name == "Button"
  end

  def component_class(name)
    name == "Button" ? ButtonComponent : nil
  end
end

RSpec.describe Nextrb::RBX::Compiler do
  before do
    stub_const("ButtonComponent", Class.new)
  end

  def parse(template, resolver = Nextrb::RBX::ComponentResolver.new)
    compiler = described_class.new("test", template, resolver)
    compiler.parse
  end

  context "when parsing" do
    it "parses plain text" do
      nodes = parse("Hello world")
      expect(nodes.count).to be(1)
      expect(nodes[0].content).to eq "Hello world"
    end

    it "parses declarations" do
      nodes = parse("<!DOCTYPE html>")
      expect(nodes.first).to be_a Nextrb::RBX::Nodes::Raw
      expect(nodes.first.content).to eq "<!DOCTYPE html>"
    end

    it "parses component tags" do
      nodes = parse("<Button></Button>", TestResolver.new)
      expect(nodes.count).to be(1)
      expect(nodes.first).to be_a Nextrb::RBX::Nodes::ComponentElement
      expect(nodes.first.name).to eq("Button")
    end

    it "parses basic html tags" do
      nodes = parse("<div></div>")
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(element.name).to eq "div"
    end

    it "parses some big nested markup with attributes" do
      code = <<~CODE
        <div foo="bar">
          <h1>Some heading</h1>
          <p class="someClass">A paragraph</p>
          <div id={dynamicId} class="divClass">
            <p>More text</p>
          </div>
        </div>
      CODE
      nodes = parse(code)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(element.name).to eq "div"
      expect(element.children.count).to eq 4
    end

    it "parses basic html tag attributes" do
      nodes = parse(%(<div class="name" id = 'title' value=yes disabled></div>))
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(element.name).to eq "div"
      expect(element.members.length).to eq(4)
    end

    it "adds a silent newline between tag name and attributes that come on the next line (for source mapping)" do
      code = <<~CODE.strip
        <div
          foo="bar">
        </div>
      CODE

      nodes = parse(code)
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(element.name).to eq "div"
      expect(element.members.length).to eq(1)
      attr = element.members[0]
      expect(attr.name).to eq("foo")
    end

    it "allows attributes to span multiple lines" do
      code = <<~CODE.strip
        <div foo="bar"
             baz="bip">
        </div>
      CODE
      nodes = parse(code)
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(element.name).to eq "div"
      expect(element.members.length).to eq(2)
      attr = element.members[0]
      expect(attr.name).to eq("foo")
      attr = element.members[1]
      expect(attr.name).to eq("baz")
    end

    it "allows attributes to be on the next line after the tag name" do
      code = <<~CODE.strip
        <input
          foo="bar"
          baz="bip"
        />
      CODE
      nodes = parse(code)
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(element.name).to eq "input"
      expect(element.members.length).to eq(2)
      attr = element.members[0]
      expect(attr.name).to eq("foo")
      attr = element.members[1]
      expect(attr.name).to eq("baz")
    end

    it "parses attributes with colon in the name" do
      nodes = parse(%(<svg version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" />))
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(element.name).to eq "svg"
      expect(element.members.length).to eq(2)
      attr = element.members[0]
      expect(attr.name).to eq("version")
      attr = element.members[1]
      expect(attr.name).to eq("xmlns:xlink")
    end

    it "doesn't try to parse tags within %q(...) string notation" do
      skip "broken"
      template = <<~RBX.strip
        <div attr={%q(
          <p>something</p>
        )} />
      RBX
      nodes = parse(template)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(element.name).to eq "div"
      expect(element.members.count).to eq 1

      attr = element.members[0]
      expect(attr.name).to eq("attr")
      expect(attr.value).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
      expect(attr.value.members.count).to eq(1)
      val = attr.value.members[0]
      expect(val).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(val.content).to eq("%q(\n  <p>something</p>\n)")
    end

    it "treats escaped \\\" as part of the attribute value" do
      nodes = parse('<input value="Some \"value\"">')
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(element.name).to eq "input"
      expect(element.members.length).to eq(1)
      attr = element.members[0]
      expect(attr).to be_instance_of(Nextrb::RBX::Nodes::HTMLAttr)
      expect(attr.name).to eq("value")
      expect(attr.value).to eq('Some \"value\"')
    end

    it "parses self-closing html tags with attributes" do
      variants = ['<input thing="value" />', '<input thing="value"/>']
      variants.each do |code|
        nodes = parse(code)
        expect(nodes.count).to be(1)
        element = nodes[0]
        expect(element).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
        expect(element.name).to eq "input"
        expect(element.members.length).to eq(1)
      end
    end

    it "parses a kwarg splat attribute" do
      nodes = parse("<div {**the_attrs}></div>")
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element.name).to eq "div"
      expect(element.members.length).to eq(1)
      attr = element.members[0]
      expect(attr).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
      expect(attr.members.count).to eq(1)
      expr = attr.members[0]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(expr.content).to eq "**the_attrs"
    end

    it "parses attributes with expression values" do
      nodes = parse("<input value={aVar}>")
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(element.name).to eq "input"
      expect(element.members.length).to eq(1)
      attr = element.members[0]
      expect(attr).to be_instance_of(Nextrb::RBX::Nodes::HTMLAttr)
      expect(attr.name).to eq("value")
      expect(attr.value).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
    end

    it "parses basic html child tags" do
      nodes = parse(%(<div><span></span></div>))
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(element.members).to be_empty
      expect(element.children.count).to eq(1)
      expect(element.children[0]).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
    end

    it "parses self-closing html tags" do
      variants = ["<input />", "<input/>", "<link>"]
      variants.each do |code|
        expect(parse(code).count).to be(1)
      end
    end

    it "parses older html4 doctype declaration" do
      template = <<~RBX.strip
        <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
      RBX
      nodes = parse(template)
      expect(nodes.first).to be_a Nextrb::RBX::Nodes::Raw
      expect(nodes.first.content).to eq "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">"
    end

    it "parses text inside a tag" do
      nodes = parse(%(<div>Hello world</div>))
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(element.members).to be_empty
      expect(element.children.count).to eq(1)
      expect(element.children[0]).to be_instance_of(Nextrb::RBX::Nodes::Raw)
      expect(element.children[0].content).to eq("Hello world")
    end

    it "parses an expression inside a tag" do
      nodes = parse("<div>{aVar}</div>")
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(element.members).to be_empty
      expect(element.children.count).to eq(1)
      expect(element.children[0]).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
      group = element.children[0]
      expect(group.members.count).to eq(1)
      expect(group.members[0]).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(group.members[0].content).to eq("aVar")
    end

    it "parses two expressions next to one another" do
      nodes = parse("{aVar}{anotherVar}")
      expect(nodes.count).to be(2)
      expect(nodes[0]).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
      expect(nodes[1]).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
    end

    it "parses an expression along with text inside a tag" do
      nodes = parse("<div>Hello {aVar}!</div>")
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(element.members).to be_empty
      expect(element.children.count).to eq(3)
      expect(element.children[0]).to be_instance_of(Nextrb::RBX::Nodes::Raw)
      expect(element.children[0].content).to eq("Hello ")
      expect(element.children[1]).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
      group = element.children[1]
      expect(group.members.count).to eq(1)
      expect(group.members[0]).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(group.members[0].content).to eq("aVar")
      expect(element.children[2]).to be_instance_of(Nextrb::RBX::Nodes::Raw)
      expect(element.children[2].content).to eq("!")
    end

    it 'treats escaped \{ as text' do
      nodes = parse('Hey \{thing\}')
      expect(nodes.count).to be(1)
      expect(nodes[0].content).to eq 'Hey \{thing\}'
    end

    it "allows for { ... } to exist within an expression (e.g. a Ruby hash)" do
      nodes = parse('{thing = { hashKey: "value" }; moreCode}')
      expect(nodes.count).to be(1)
      expr = nodes[0]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
      expect(expr.members.count).to eq(1)
    end

    it "allows for expressions to have arbitrary brackets inside quoted strings" do
      nodes = parse(%({something "quoted {bracket}" '{}' "'{'" more}))
      expect(nodes.count).to be(1)
      expr = nodes[0]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
      expect(expr.members.count).to eq(1)
    end

    it "doesn't consider escaped quotes to end an expression quoted string" do
      nodes = parse('{"he said \"hello {there}\" loudly"}')
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
      expect(element.members.count).to eq(1)
      expr = element.members[0]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(expr.content).to eq('"he said \"hello {there}\" loudly"')
    end

    it "parses an expression that starts with a tag" do
      nodes = parse("{<h1>Title</h1>}")
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
      expect(element.members.count).to eq(1)
      expr = element.members[0]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
    end

    it "parses tags within a boolean expression" do
      nodes = parse("{true && <h1>Is true</h1>}")
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
      expect(element.members.count).to eq(2)
      expr = element.members[0]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(expr.content).to eq("true && ")
      expr = element.members[1]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(expr.name).to eq("h1")
    end

    it "parses self-closing tags within a boolean expression" do
      nodes = parse("{true && <br />}")
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
      expect(element.members.count).to eq(2)
      expr = element.members[0]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(expr.content).to eq("true && ")
      expr = element.members[1]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(expr.name).to eq("br")
    end

    it "parses nested tags within a boolean expression" do
      nodes = parse("{true && <h1><span>Hey</span></h1>}")
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
      expect(element.members.count).to eq(2)
      expr = element.members[0]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(expr.content).to eq("true && ")
      expr = element.members[1]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(expr.name).to eq("h1")
      expect(expr.children.count).to eq(1)
      child = expr.children[0]
      expect(child).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(child.name).to eq("span")
    end

    it "does not specially tokenize boolean expressions that aren't followed by a tag" do
      nodes = parse("{true && 'hey'}")
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
      expect(element.members.count).to eq(1)
      expr = element.members[0]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(expr.content).to eq("true && 'hey'")
    end

    it "allows for sub-expressions within a boolean expression tag" do
      nodes = parse("{true && <h1>Is {'hello'.upcase}</h1>}")
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
      expect(element.members.count).to eq(2)
      expr = element.members[0]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(expr.content).to eq("true && ")
      expr = element.members[1]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(expr.children.count).to eq(2)

      element = element.members[1]
      expr = element.children[0]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::Raw)
      expect(expr.content).to eq("Is ")
      expr = element.children[1]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
    end

    it "parses tags within a ternary expression" do
      nodes = parse("{true ? <h1>Yes</h1> : <h2>No</h2>}")
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
      expect(element.members.count).to eq(4)
      expr = element.members[0]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(expr.content).to eq("true ? ")
      expr = element.members[1]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(expr.name).to eq("h1")
      expr = element.members[2]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(expr.content).to eq(" : ")
      expr = element.members[3]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(expr.name).to eq("h2")
    end

    it "parses self-closing tags within a ternary expression" do
      nodes = parse("{true ? <br /> : <input />}")
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
      expect(element.members.count).to eq(4)
      expr = element.members[0]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(expr.content).to eq("true ? ")
      expr = element.members[1]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(expr.name).to eq("br")
      expr = element.members[2]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(expr.content).to eq(" : ")
      expr = element.members[3]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(expr.name).to eq("input")
    end

    it "parses tags within a boolean expression including an OR operator" do
      nodes = parse("{true || <p>Yes</p>}")
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
      expect(element.members.count).to eq(2)
      expr = element.members[0]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(expr.content).to eq("true || ")
      expr = element.members[1]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(expr.name).to eq("p")
    end

    it "parses tags within a do..end block" do
      template = <<~RBX.strip
        {3.times do
          <p>Hello</p>
        end}
      RBX
      nodes = parse(template)
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
      expect(element.members.count).to eq(3)
      expr = element.members[0]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(expr.content).to eq("3.times do\n  ")
      expr = element.members[1]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(expr.name).to eq("p")
      expr = element.members[2]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(expr.content).to eq("\nend")
    end

    it "parses tags within a do |var|..end block" do
      template = <<~RBX.strip
        {3.times do |n|
          <p>Hello</p>
        end}
      RBX
      nodes = parse(template)
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
      expect(element.members.count).to eq(3)
      expr = element.members[0]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(expr.content).to eq("3.times do |n|\n  ")
      expr = element.members[1]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(expr.name).to eq("p")
      expr = element.members[2]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(expr.content).to eq("\nend")
    end

    it "parses tags within a {..} block" do
      nodes = parse("{3.times { <p>Hello</p> }}")
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
      expect(element.members.count).to eq(3)
      expr = element.members[0]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(expr.content).to eq("3.times { ")
      expr = element.members[1]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(expr.name).to eq("p")
      expr = element.members[2]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(expr.content).to eq(" }")
    end

    it "parses tags within a {|var|..} block" do
      nodes = parse("{3.times { |n| <p>Hello</p> }}")
      expect(nodes.count).to be(1)
      element = nodes[0]
      expect(element).to be_instance_of(Nextrb::RBX::Nodes::ExpressionGroup)
      expect(element.members.count).to eq(3)
      expr = element.members[0]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(expr.content).to eq("3.times { |n| ")
      expr = element.members[1]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::HTMLElement)
      expect(expr.name).to eq("p")
      expr = element.members[2]
      expect(expr).to be_instance_of(Nextrb::RBX::Nodes::Expression)
      expect(expr.content).to eq(" }")
    end
  end
end
