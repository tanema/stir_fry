# frozen_string_literal: true

RSpec.describe Nextrb::RBX::Compiler do
  def compile(template)
    described_class.compile(Nextrb::RBX::Parser.parse("test", template))
  end

  it "outputs plain text" do
    result = compile("Hello world")
    expected = <<~RBX
      buffer = String.new
      buffer << 'Hello world'
      buffer
    RBX
    expect(result).to eq expected
  end

  it "escapes single quotes and backslashes in text so the generated code stays valid ruby" do
    result = compile(%(Don't use a \\ here))
    expected = <<~RBX
      buffer = String.new
      buffer << 'Don\\'t use a \\\\ here'
      buffer
    RBX
    expect(result).to eq expected
    expect(eval(result)).to eq "Don't use a \\ here" # rubocop:disable Security/Eval
  end

  it "outputs declarations directly" do
    result = compile("<!DOCTYPE html>")
    expected = <<~RBX
      buffer = String.new
      buffer << '<!DOCTYPE html>'
      buffer
    RBX
    expect(result).to eq expected

    template = %(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">)
    result = compile(template)
    expected = <<~RBX
      buffer = String.new
      buffer << '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">'
      buffer
    RBX
    expect(result).to eq expected
  end

  it "compiles component tags" do
    result = compile("<Button name='bobby'>test</Button>")
    expected = <<~RBX
      buffer = String.new
      buffer << ::Button.new(name: "bobby").capture do |buffer|
        buffer << 'test'
      end.render
      buffer
    RBX
    expect(result).to eq expected
  end

  it "compiles basic html tags" do
    result = compile("<div></div>")
    expected = <<~RBX
      buffer = String.new
      buffer << '<div></div>'
      buffer
    RBX
    expect(result).to eq expected
  end

  it "compiles self-closing html tags with attributes" do
    result = compile(%(<input thing="value"/>))
    expected = <<~RBX
      buffer = String.new
      buffer << '<input thing="value"/>'
      buffer
    RBX
    expect(result).to eq expected
  end

  it "compiles some big nested markup with attributes" do
    template = <<~CODE
      <div foo="bar">
        <h1>Some heading</h1>
        <p class="someClass">A paragraph</p>
        <div id={dynamicId} class="divClass">
          <p>More text</p>
        </div>
      </div>
    CODE
    expected = <<~RBX
      buffer = String.new
      buffer << '<div foo="bar"><h1>Some heading</h1><p class="someClass">A paragraph</p><div id="'+::Nextrb::RBX.escape((dynamicId))+'" class="divClass"><p>More text</p></div></div>'
      buffer
    RBX
    expect(compile(template)).to eq expected
  end

  it "parses basic html tag attributes" do
    result = compile(%(<div class="name" id = 'title' value=yes disabled></div>))
    expected = <<~RBX
      buffer = String.new
      buffer << '<div class="name" id="title" value=yes disabled></div>'
      buffer
    RBX
    expect(result).to eq expected
  end

  it "compiles attributes with colon in the name" do
    result = compile(%(<svg version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" />))
    expected = <<~RBX
      buffer = String.new
      buffer << '<svg version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink"/>'
      buffer
    RBX
    expect(result).to eq expected
  end

  it "can render expression attributes on a normal html tag" do
    template = '<p class={@dynamic_class}>Hello {"world".upcase}</p>'
    expected = <<~RBX
      buffer = String.new
      buffer << '<p class="'+::Nextrb::RBX.escape((@dynamic_class))+'">Hello '+::Nextrb::RBX.escape(("world".upcase))+'</p>'
      buffer
    RBX
    expect(compile(template)).to eq expected
  end

  it "handles quoted tags" do
    template = <<~RBX.strip
      <div attr={%q(<p>something</p>)} />
    RBX
    result = compile(template)
    expected = <<~RBX
      buffer = String.new
      buffer << '<div attr="'+::Nextrb::RBX.escape((%q(<p>something</p>)))+'"/>'
      buffer
    RBX
    expect(result).to eq expected
  end

  it "parses a kwarg splat attribute" do
    result = compile("<div {**the_attrs}></div>")
    expected = <<~RBX
      buffer = String.new
      buffer << '<div'+(tag_kwargs(**the_attrs)).to_s+'></div>'
      buffer
    RBX
    expect(result).to eq expected
  end

  it "compiles two expressions next to one another" do
    result = compile("{aVar}{anotherVar}")
    expected = <<~RBX
      buffer = String.new
      buffer << ::Nextrb::RBX.escape((aVar))
      buffer << ::Nextrb::RBX.escape((anotherVar))
      buffer
    RBX
    expect(result).to eq expected
  end

  it "allows for { ... } to exist within an expression (e.g. a Ruby hash)" do
    result = compile('{thing = { hashKey: "value" }; moreCode}')
    expected = <<~RBX
      buffer = String.new
      buffer << ::Nextrb::RBX.escape((thing = { hashKey: "value" }; moreCode))
      buffer
    RBX
    expect(result).to eq expected
  end

  it "compiles an expression that starts with a tag" do
    result = compile("{<h1>Title</h1>}")
    expected = <<~RBX
      buffer = String.new
      buffer << (('<h1>Title</h1>')).to_s
      buffer
    RBX
    expect(result).to eq(expected)
  end

  it "compiles tags within a boolean expression" do
    result = compile("{true && <h1>Is true</h1>}")
    expected = <<~RBX
      buffer = String.new
      buffer << (true && ('<h1>Is true</h1>')).to_s
      buffer
    RBX
    expect(result).to eq(expected)
  end

  it "compiles self-closing tags within a boolean expression" do
    result = compile("{true && <br />}")
    expected = <<~RBX
      buffer = String.new
      buffer << (true && ('<br/>')).to_s
      buffer
    RBX
    expect(result).to eq(expected)
  end

  it "parses nested tags within a boolean expression" do
    result = compile("{true && <h1><span>Hey</span></h1>}")
    expected = <<~RBX
      buffer = String.new
      buffer << (true && ('<h1><span>Hey</span></h1>')).to_s
      buffer
    RBX
    expect(result).to eq expected
  end

  it "does not specially tokenize boolean expressions that aren't followed by a tag" do
    result = compile("{true && 'hey'}")
    expected = <<~RBX
      buffer = String.new
      buffer << ::Nextrb::RBX.escape((true && 'hey'))
      buffer
    RBX
    expect(result).to eq expected
  end

  it "allows for sub-expressions within a boolean expression tag" do
    result = compile("{true && <h1>Is {'hello'.upcase}</h1>}")
    expected = <<~RBX
      buffer = String.new
      buffer << (true && ('<h1>Is '+::Nextrb::RBX.escape(('hello'.upcase))+'</h1>')).to_s
      buffer
    RBX
    expect(result).to eq expected
  end

  it "parses tags within a ternary expression" do
    result = compile("{true ? <h1>Yes</h1> : <h2>No</h2>}")
    expected = <<~RBX
      buffer = String.new
      buffer << (true ? ('<h1>Yes</h1>') : ('<h2>No</h2>')).to_s
      buffer
    RBX
    expect(result).to eq expected
  end

  it "parses self-closing tags within a ternary expression" do
    result = compile("{true ? <br /> : <input />}")
    expected = <<~RBX
      buffer = String.new
      buffer << (true ? ('<br/>') : ('<input/>')).to_s
      buffer
    RBX
    expect(result).to eq expected
  end

  it "parses tags within a boolean expression including an OR operator" do
    result = compile("{true || <p>Yes</p>}")
    expected = <<~RBX
      buffer = String.new
      buffer << (true || ('<p>Yes</p>')).to_s
      buffer
    RBX
    expect(result).to eq expected
  end

  it "parses tags within a do..end block" do
    template = <<~RBX.strip
      {3.times.map do
        <p>Hello</p>
      end.join}
    RBX
    result = compile(template)
    expected = <<~RBX
      buffer = String.new
      buffer << (3.times.map do
        ('<p>Hello</p>')
      end.join).to_s
      buffer
    RBX
    expect(result).to eq expected
  end

  it "parses tags within a do |var|..end block" do
    template = <<~RBX.strip
      {3.times.map do |n|
        <p>Hello</p>
      end.join}
    RBX
    result = compile(template)
    expected = <<~RBX
      buffer = String.new
      buffer << (3.times.map do |n|
        ('<p>Hello</p>')
      end.join).to_s
      buffer
    RBX
    expect(result).to eq expected
  end

  it "parses tags within a {..} block" do
    result = compile("{3.times.map { <p>Hello</p> }.join}")
    expected = <<~RBX
      buffer = String.new
      buffer << (3.times.map { ('<p>Hello</p>') }.join).to_s
      buffer
    RBX
    expect(result).to eq expected
  end

  it "handled sequences in expression groups" do
    result = compile("<ul>{[1, 2, 3].map { |n| <li>{n}</li> }.join}</ul>")
    expected = <<~RBX
      buffer = String.new
      buffer << '<ul>'+([1, 2, 3].map { |n| ('<li>'+::Nextrb::RBX.escape((n))+'</li>') }.join).to_s+'</ul>'
      buffer
    RBX
    expect(result).to eq expected
  end

  it "escapes html in text expressions" do
    result = compile("<p>{user_input}</p>")
    user_input = "<script>alert(1)</script>" # rubocop:disable Lint/UselessAssignment
    expect(eval(result)).to eq "<p>&lt;script&gt;alert(1)&lt;/script&gt;</p>" # rubocop:disable Security/Eval
  end

  it "escapes html in attribute expressions" do
    result = compile("<div id={user_input}></div>")
    user_input = %(" onmouseover="alert(1)) # rubocop:disable Lint/UselessAssignment
    expect(eval(result)).to eq %(<div id="&quot; onmouseover=&quot;alert(1)"></div>) # rubocop:disable Security/Eval
  end

  it "does not double escape markup composed via map/join" do
    result = compile("{[1, 2].map { |n| <li>{n}</li> }.join}")
    expect(eval(result)).to eq "<li>1</li><li>2</li>" # rubocop:disable Security/Eval
  end
end
