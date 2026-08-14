# frozen_string_literal: true

class TestResolver
  def component?(name)
    name == "Button"
  end

  def component_class(name)
    name == "Button" ? ButtonComponent : nil
  end
end

RSpec.describe Nextrb::RBX::Lexer do
  before do
    stub_const("ButtonComponent", Class.new)
  end

  it "tokenizes text" do
    tokens = described_class.tokenize("Hello world")
    expect(tokens).to eq [[:TEXT, "Hello world"]]
  end

  it "tokenizes html tags" do
    subject = described_class.new("<div></div>")
    expect(subject.tokenize).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END]
    ]
  end

  it "tokenizes component tags" do
    tokens = described_class.tokenize("<Button></Button>", TestResolver.new)
    expect(tokens).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "Button", type: :component, component_class: ButtonComponent }],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:TAG_NAME, "Button"],
      [:CLOSE_TAG_END]
    ]
  end

  it "tokenizes self-closing html tags" do
    variants = ["<input />", "<input/>"]
    variants.each do |code|
      expect(described_class.tokenize(code)).to eq [
        [:OPEN_TAG_DEF],
        [:TAG_DETAILS, { name: "input", type: :html }],
        [:CLOSE_TAG_DEF],
        [:OPEN_TAG_END],
        [:CLOSE_TAG_END]
      ]
    end
  end

  it "tokenizes html5 doctype declaration" do
    expect(described_class.tokenize("<!DOCTYPE html>")).to eq [[:DECLARATION, "<!DOCTYPE html>"]]
  end

  it "tokenizes older html4 doctype declaration" do
    template = <<~RBX.strip
      <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
    RBX
    expect(described_class.tokenize(template)).to eq [
      [
        :DECLARATION,
        "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">"
      ]
    ]
  end

  it "tokenizes nested self-closing html tags" do
    expect(described_class.tokenize("<div><br /></div>")).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "br", type: :html }],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END]
    ]
  end

  it "tokenizes self-closing html tags with attributes" do
    variants = ['<input thing="value" />', '<input thing="value"/>']
    variants.each do |code|
      expect(described_class.tokenize(code)).to eq [
        [:OPEN_TAG_DEF],
        [:TAG_DETAILS, { name: "input", type: :html }],
        [:OPEN_ATTRS],
        [:ATTR_NAME, "thing"],
        [:OPEN_ATTR_VALUE],
        [:TEXT, "value"],
        [:CLOSE_ATTR_VALUE],
        [:CLOSE_ATTRS],
        [:CLOSE_TAG_DEF],
        [:OPEN_TAG_END],
        [:CLOSE_TAG_END]
      ]
    end
  end

  it "tokenizes text inside a tag" do
    expect(described_class.tokenize("<div>Hello world</div>")).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Hello world"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END]
    ]
  end

  it "tokenizes an expression inside a tag" do
    expect(described_class.tokenize("<div>{aVar}</div>")).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:CLOSE_TAG_DEF],
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "aVar"],
      [:CLOSE_EXPRESSION],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END]
    ]
  end

  it "tokenizes two expressions next to one another" do
    expect(described_class.tokenize("{aVar}{anotherVar}")).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "aVar"],
      [:CLOSE_EXPRESSION],
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "anotherVar"],
      [:CLOSE_EXPRESSION]
    ]
  end

  it "tokenizes an expression along with text inside a tag" do
    expect(described_class.tokenize("<div>Hello {aVar}!</div>")).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Hello "],
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "aVar"],
      [:CLOSE_EXPRESSION],
      [:TEXT, "!"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END]
    ]
  end

  it 'treats escaped \{ as text' do
    expect(described_class.tokenize('Hey \{thing\}')).to eq [[:TEXT, 'Hey \{thing\}']]
  end

  it "allows for { ... } to exist within an expression (e.g. a Ruby hash)" do
    expect(described_class.tokenize('{thing = { hashKey: "value" }; moreCode}')).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, 'thing = { hashKey: "value" }; moreCode'],
      [:CLOSE_EXPRESSION]
    ]
  end

  it "allows for expressions to have arbitrary brackets inside quoted strings" do
    expect(described_class.tokenize('{something "quoted {bracket}" \'{}\' "\'{\'" more}')).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, 'something "quoted {bracket}" \'{}\' "\'{\'" more'],
      [:CLOSE_EXPRESSION]
    ]
  end

  it "doesn't consider escaped quotes to end an expression quoted string" do
    expect(described_class.tokenize('{"he said \"hello {there}\" loudly"}')).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, '"he said \"hello {there}\" loudly"'],
      [:CLOSE_EXPRESSION]
    ]
  end

  it "tokenizes an expression that starts with a tag" do
    expect(described_class.tokenize("{<h1>Title</h1>}")).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, ""],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "h1", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Title"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "h1"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, ""],
      [:CLOSE_EXPRESSION]
    ]
  end

  it "tokenizes tags within a boolean expression" do
    expect(described_class.tokenize("{true && <h1>Is true</h1>}")).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "true && "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "h1", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Is true"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "h1"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, ""],
      [:CLOSE_EXPRESSION]
    ]
  end

  it "tokenizes self-closing tags within a boolean expression" do
    template_string = <<~RBX.strip
      {true && <br />}
    RBX

    expect(described_class.tokenize(template_string)).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "true && "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "br", type: :html }],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, ""],
      [:CLOSE_EXPRESSION]
    ]
  end

  it "tokenizes nested tags within a boolean expression" do
    template_string = <<~RBX.strip
      {true && <h1><span>Hey</span></h1>}
    RBX

    expect(described_class.tokenize(template_string)).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "true && "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "h1", type: :html }],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "span", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Hey"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "span"],
      [:CLOSE_TAG_END],
      [:OPEN_TAG_END],
      [:TAG_NAME, "h1"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, ""],
      [:CLOSE_EXPRESSION]
    ]
  end

  it "does not specially tokenize boolean expressions that aren't followed by a tag" do
    expect(described_class.tokenize("{true && 'hey'}")).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "true && 'hey'"],
      [:CLOSE_EXPRESSION]
    ]
  end

  it "allows for sub-expressions within a boolean expression tag" do
    expect(described_class.tokenize("{true && <h1>Is {'hello'.upcase}</h1>}")).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "true && "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "h1", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Is "],
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "'hello'.upcase"],
      [:CLOSE_EXPRESSION],
      [:OPEN_TAG_END],
      [:TAG_NAME, "h1"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, ""],
      [:CLOSE_EXPRESSION]
    ]
  end

  it "tokenizes tags within a ternary expression" do
    expect(described_class.tokenize("{true ? <h1>Yes</h1> : <h2>No</h2>}")).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "true ? "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "h1", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Yes"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "h1"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, " : "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "h2", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "No"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "h2"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, ""],
      [:CLOSE_EXPRESSION]
    ]
  end

  it "tokenizes self-closing tags within a ternary expression" do
    expect(described_class.tokenize("{true ? <br /> : <input />}")).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "true ? "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "br", type: :html }],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, " : "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "input", type: :html }],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, ""],
      [:CLOSE_EXPRESSION]
    ]
  end

  it "tokenizes tags within a boolean expression including an OR operator" do
    expect(described_class.tokenize("{true || <p>Yes</p>}")).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "true || "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "p", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Yes"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "p"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, ""],
      [:CLOSE_EXPRESSION]
    ]
  end

  it "tokenizes tags within a do..end block" do
    template = <<~RBX.strip
      {3.times do
        <p>Hello</p>
      end}
    RBX
    expect(described_class.tokenize(template)).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "3.times do\n  "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "p", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Hello"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "p"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, "\nend"],
      [:CLOSE_EXPRESSION]
    ]
  end

  it "tokenizes tags within a do |var|..end block" do
    template = <<~RBX.strip
      {3.times do |n|
        <p>Hello</p>
      end}
    RBX
    expect(described_class.tokenize(template)).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "3.times do |n|\n  "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "p", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Hello"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "p"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, "\nend"],
      [:CLOSE_EXPRESSION]
    ]
  end

  it "tokenizes tags within a {..} block" do
    expect(described_class.tokenize("{3.times { <p>Hello</p> }}")).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "3.times { "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "p", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Hello"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "p"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, " }"],
      [:CLOSE_EXPRESSION]
    ]
  end

  it "tokenizes tags within a {|var|..} block" do
    expect(described_class.tokenize("{3.times { |n| <p>Hello</p> }}")).to eq [
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "3.times { |n| "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "p", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Hello"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "p"],
      [:CLOSE_TAG_END],
      [:EXPRESSION_BODY, " }"],
      [:CLOSE_EXPRESSION]
    ]
  end

  it "doesn't try to parse tags within %q(...) string notation" do
    template_string = <<~RBX.strip
      <div attr={%q(
        <p>something</p>
      )} />
    RBX
    expect(described_class.tokenize(template_string)).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "attr"],
      [:OPEN_ATTR_VALUE],
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "%q(\n  <p>something</p>\n)"],
      [:CLOSE_EXPRESSION],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END]
    ]
  end

  it "tokenizes value-less attributes" do
    expect(described_class.tokenize("<button disabled>")).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "button", type: :html }],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "disabled"],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF]
    ]
  end

  it "tokenizes attributes with double-quoted string values" do
    expect(described_class.tokenize('<button type="submit">')).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "button", type: :html }],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "type"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "submit"],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF]
    ]
  end

  it "treats escaped \\\" as part of the attribute value" do
    expect(described_class.tokenize('<input value="Some \"value\"">')).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "input", type: :html }],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "value"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, 'Some \"value\"'],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF]
    ]
  end

  it "tokenizes attributes with expression values" do
    expect(described_class.tokenize("<input value={aVar}>")).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "input", type: :html }],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "value"],
      [:OPEN_ATTR_VALUE],
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "aVar"],
      [:CLOSE_EXPRESSION],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF]
    ]
  end

  it "tokenizes a combination of types of attributes" do
    expect(described_class.tokenize('<div foo bar="baz" thing={exprValue}>')).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "foo"],
      [:ATTR_NAME, "bar"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "baz"],
      [:CLOSE_ATTR_VALUE],
      [:ATTR_NAME, "thing"],
      [:OPEN_ATTR_VALUE],
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "exprValue"],
      [:CLOSE_EXPRESSION],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF]
    ]
  end

  it "tokenizes a kwarg splat attribute" do
    expect(described_class.tokenize("<div {**the_attrs}>")).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:OPEN_ATTRS],
      [:OPEN_ATTR_SPLAT],
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "the_attrs"],
      [:CLOSE_EXPRESSION],
      [:CLOSE_ATTR_SPLAT],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF]
    ]
  end

  it "adds a silent newline between tag name and attributes that come on the next line (for source mapping)" do
    code = <<~CODE.strip
      <div
        foo="bar">
      </div>
    CODE

    expect(described_class.tokenize(code)).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:NEWLINE],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "foo"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "bar"],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF],
      [:TEXT, "\n"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END]
    ]
  end

  it "allows attributes to span multiple lines" do
    code = <<~CODE.strip
      <div foo="bar"
           baz="bip">
      </div>
    CODE

    expect(described_class.tokenize(code)).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "foo"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "bar"],
      [:CLOSE_ATTR_VALUE],
      [:NEWLINE],
      [:ATTR_NAME, "baz"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "bip"],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF],
      [:TEXT, "\n"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END]
    ]
  end

  it "allows attributes to be on the next line after the tag name" do
    code = <<~CODE.strip
      <input
        foo="bar"
        baz="bip"
      />
    CODE

    expect(described_class.tokenize(code)).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "input", type: :html }],
      [:NEWLINE],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "foo"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "bar"],
      [:CLOSE_ATTR_VALUE],
      [:NEWLINE],
      [:ATTR_NAME, "baz"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "bip"],
      [:CLOSE_ATTR_VALUE],
      [:NEWLINE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END]
    ]
  end

  it "tokenizes attributes with colon in the name" do
    code = <<~CODE.strip
      <svg version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" />
    CODE

    expect(described_class.tokenize(code)).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "svg", type: :html }],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "version"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "1.1"],
      [:CLOSE_ATTR_VALUE],
      [:ATTR_NAME, "xmlns:xlink"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "http://www.w3.org/1999/xlink"],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF],
      [:OPEN_TAG_END],
      [:CLOSE_TAG_END]
    ]
  end

  it "tokenizes some big nested markup with attributes" do
    code = <<~CODE
      <div foo="bar">
        <h1>Some heading</h1>
        <p class="someClass">A paragraph</p>
        <div id={dynamicId} class="divClass">
          <p>More text</p>
        </div>
      </div>
    CODE

    expect(described_class.tokenize(code)).to eq [
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "foo"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "bar"],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF],
      [:TEXT, "\n  "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "h1", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "Some heading"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "h1"],
      [:CLOSE_TAG_END],
      [:TEXT, "\n  "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "p", type: :html }],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "class"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "someClass"],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF],
      [:TEXT, "A paragraph"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "p"],
      [:CLOSE_TAG_END],
      [:TEXT, "\n  "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "div", type: :html }],
      [:OPEN_ATTRS],
      [:ATTR_NAME, "id"],
      [:OPEN_ATTR_VALUE],
      [:OPEN_EXPRESSION],
      [:EXPRESSION_BODY, "dynamicId"],
      [:CLOSE_EXPRESSION],
      [:CLOSE_ATTR_VALUE],
      [:ATTR_NAME, "class"],
      [:OPEN_ATTR_VALUE],
      [:TEXT, "divClass"],
      [:CLOSE_ATTR_VALUE],
      [:CLOSE_ATTRS],
      [:CLOSE_TAG_DEF],
      [:TEXT, "\n    "],
      [:OPEN_TAG_DEF],
      [:TAG_DETAILS, { name: "p", type: :html }],
      [:CLOSE_TAG_DEF],
      [:TEXT, "More text"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "p"],
      [:CLOSE_TAG_END],
      [:TEXT, "\n  "],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END],
      [:TEXT, "\n"],
      [:OPEN_TAG_END],
      [:TAG_NAME, "div"],
      [:CLOSE_TAG_END],
      [:TEXT, "\n"]
    ]
  end

  context "with comments" do
    it "tokenizes lines starting with # as NEWLINE" do
      template_string = <<~RBX.strip
        Hello
        # some comment
        world
      RBX
      expect(described_class.tokenize(template_string)).to eq [
        [:TEXT, "Hello\n"],
        [:NEWLINE],
        [:TEXT, "world"]
      ]
    end

    it "tokenizes the first line if starting with # as NEWLINE" do
      template_string = <<~RBX.strip
        # some comment
        Hello world
      RBX
      expect(described_class.tokenize(template_string)).to eq [
        [:NEWLINE],
        [:TEXT, "Hello world"]
      ]
    end

    it "tokenizes the last line if starting with # as NEWLINE" do
      template_string = <<~RBX.strip
        Hello world
        # some comment
      RBX
      expect(described_class.tokenize(template_string)).to eq [
        [:TEXT, "Hello world\n"],
        [:NEWLINE]
      ]
    end

    it "trims trailing whitespace from text before a comment line" do
      template_string = <<~RBX.strip
        Hello world
          # some indented comment
        Another text
      RBX
      expect(described_class.tokenize(template_string)).to eq [
        [:TEXT, "Hello world\n"],
        [:NEWLINE],
        [:TEXT, "Another text"]
      ]
    end

    it "allows comments as children of tags" do
      template_string = <<~RBX.strip
        <div>
          # some comment
        </div>
      RBX
      expect(described_class.tokenize(template_string)).to eq [
        [:OPEN_TAG_DEF],
        [:TAG_DETAILS, { name: "div", type: :html }],
        [:CLOSE_TAG_DEF],
        [:TEXT, "\n"],
        [:NEWLINE],
        [:OPEN_TAG_END],
        [:TAG_NAME, "div"],
        [:CLOSE_TAG_END]
      ]
    end

    it "treats an escaped \\# as TEXT" do
      expect(described_class.tokenize('\# not a comment')).to eq [
        [:TEXT, '\# not a comment']
      ]
    end
  end
end
