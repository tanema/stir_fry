# frozen_string_literal: true

RSpec.describe RBX::Parser do
  def parse(template)
    described_class.new("test", template).parse
  end

  def node(kind, **args)
    RBX::Parser::Node.new(kind: kind, **args)
  end

  it "parses plain text" do
    nodes = parse("Hello world")
    expect(nodes.count).to be(1)
    expect(nodes[0].content).to eq "Hello world"
  end

  it "parses declarations" do
    nodes = parse("<!DOCTYPE html>")
    expect(nodes.first).to eq node(:raw, content: "<!DOCTYPE html>")
  end

  it "parses older html4 doctype declaration" do
    template = <<~RBX.strip
      <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
    RBX
    expected = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">"
    expect(parse(template)).to eq [node(:raw, content: expected)]
  end

  it "parses component tags" do
    expect(parse("<Button></Button>")).to eq [node(:component, name: "Button", void: false)]
  end

  it "parses basic html tags" do
    expect(parse("<div></div>")).to eq [node(:html, name: "div", void: false)]
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
    expect(parse(code)).to eq [
      node(:html,
           name: "div",
           void: false,
           attributes: [
             node(:attribute, name: "foo", content: node(:raw, content: '"bar"'))
           ],
           content: [
             node(:html, name: "h1", void: false, content: [node(:raw, content: "Some heading")]),
             node(:html, name: "p", void: false,
                         attributes: [node(:attribute, name: "class", content: node(:raw, content: '"someClass"'))],
                         content: [node(:raw, content: "A paragraph")]),
             node(:html, name: "div", void: false,
                         attributes: [
                           node(:attribute, name: "id", content: node(:expr_group, content: [
                                                                        node(:expression, content: "dynamicId")
                                                                      ])),
                           node(:attribute, name: "class", content: node(:raw, content: '"divClass"'))
                         ],
                         content: [
                           node(:html, name: "p", void: false, content: [node(:raw, content: "More text")]),
                           node(:raw, content: "\n  ")
                         ]),
             node(:raw, content: "\n")
           ]),
      node(:raw, content: "\n")
    ]
  end

  it "parses basic html tag attributes" do
    actual = parse(%(<div class="name" id = 'title' value=yes disabled></div>))
    expect(actual).to eq [
      node(:html, name: "div", void: false, attributes: [
             node(:attribute, name: "class", content: node(:raw, content: '"name"')),
             node(:attribute, name: "id", content: node(:raw, content: '"title"')),
             node(:attribute, name: "value", content: node(:raw, content: "yes")),
             node(:attribute, name: "disabled")
           ])
    ]
  end

  it "adds a silent newline between tag name and attributes that come on the next line (for source mapping)" do
    code = <<~CODE.strip
      <div
        foo="bar">
      </div>
    CODE

    expect(parse(code)).to eq [
      node(:html, name: "div", void: false,
                  attributes: [node(:attribute, name: "foo", content: node(:raw, content: '"bar"'))],
                  content: [node(:raw, content: "\n")])
    ]
  end

  it "allows attributes to span multiple lines" do
    code = <<~CODE.strip
      <div foo="bar"
           baz="bip">
      </div>
    CODE
    expect(parse(code)).to eq [
      node(:html, name: "div", void: false,
                  attributes: [
                    node(:attribute, name: "foo", content: node(:raw, content: '"bar"')),
                    node(:attribute, name: "baz", content: node(:raw, content: '"bip"'))
                  ],
                  content: [node(:raw, content: "\n")])
    ]
  end

  it "allows attributes to be on the next line after the tag name" do
    code = <<~CODE.strip
      <input
        foo="bar"
        baz="bip"
      />
    CODE
    expect(parse(code)).to eq [
      node(:html, name: "input", void: true,
                  attributes: [
                    node(:attribute, name: "foo", content: node(:raw, content: '"bar"')),
                    node(:attribute, name: "baz", content: node(:raw, content: '"bip"'))
                  ])
    ]
  end

  it "parses attributes with colon in the name" do
    nodes = parse(%(<svg version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" />))
    expect(nodes).to eq [
      node(:html, name: "svg", void: true,
                  attributes: [
                    node(:attribute, name: "version", content: node(:raw, content: '"1.1"')),
                    node(:attribute, name: "xmlns:xlink", content: node(:raw, content: '"http://www.w3.org/1999/xlink"'))
                  ])
    ]
  end

  it "doesn't try to parse tags within %q(...) string notation" do
    template = <<~RBX.strip
      <div attr={%q(
        <p>something</p>
      )} />
    RBX
    expect(parse(template)).to eq [
      node(:html, name: "div", void: true, attributes: [
             node(:attribute, name: "attr", content: node(:expr_group, content: [
                                                            node(:expression, content: "%q(\n  <p>something</p>\n)")
                                                          ]))
           ])
    ]
  end

  it "treats escaped \\\" as part of the attribute value" do
    expect(parse('<input value="Some \"value\"">')).to eq [
      node(:html, name: "input", void: true, attributes: [
             node(:attribute, name: "value", content: node(:raw, content: '"Some \"value\""'))
           ])
    ]
  end

  it "parses self-closing html tags with attributes" do
    expected = [node(:html, name: "input", void: true, attributes: [
                       node(:attribute, name: "thing", content: node(:raw, content: '"value"'))
                     ])]
    expect(parse('<input thing="value" />')).to eq expected
    expect(parse('<input thing="value"/>')).to eq expected
  end

  it "parses a kwarg splat attribute" do
    expect(parse("<div {**the_attrs}></div>")).to eq [
      node(:html, name: "div", void: false, attributes: [
             node(:expr_group, content: [
                    node(:expression, content: "**the_attrs")
                  ])
           ])
    ]
  end

  it "parses attributes with expression values" do
    expect(parse("<input value={aVar}>")).to eq [
      node(:html, name: "input", void: true, attributes: [
             node(:attribute, name: "value", content: node(:expr_group, content: [
                                                             node(:expression, content: "aVar")
                                                           ]))
           ])
    ]
  end

  it "parses basic html child tags" do
    expect(parse(%(<div><span></span></div>))).to eq [
      node(:html, name: "div", void: false, content: [node(:html, name: "span", void: false)])
    ]
  end

  it "parses self-closing html tags" do
    expect(parse("<input />")).to eq [node(:html, name: "input", void: true)]
    expect(parse("<input/>")).to eq [node(:html, name: "input", void: true)]
    expect(parse("<link>")).to eq [node(:html, name: "link", void: true)]
  end

  it "parses text inside a tag" do
    expected = [node(:html, name: "div", void: false, content: [node(:raw, content: "Hello world")])]
    expect(parse(%(<div>Hello world</div>))).to eq expected
  end

  it "parses an expression inside a tag" do
    expect(parse("<div>{aVar}</div>")).to eq [
      node(:html, name: "div", void: false,
                  content: [node(:expr_group, content: [node(:expression, content: "aVar")])])
    ]
  end

  it "parses two expressions next to one another" do
    expect(parse("{aVar}{anotherVar}")).to eq [
      node(:expr_group, content: [node(:expression, content: "aVar")]),
      node(:expr_group, content: [node(:expression, content: "anotherVar")])
    ]
  end

  it "parses an expression along with text inside a tag" do
    expect(parse("<div>Hello {aVar}!</div>")).to eq [
      node(:html, name: "div", void: false, content: [
             node(:raw, content: "Hello "),
             node(:expr_group, content: [node(:expression, content: "aVar")]),
             node(:raw, content: "!")
           ])
    ]
  end

  it 'treats escaped \{ as text' do
    expect(parse('Hey \{thing\}')).to eq [node(:raw, content: "Hey \\{thing\\}")]
  end

  it "allows for { ... } to exist within an expression (e.g. a Ruby hash)" do
    nodes = parse('{thing = { hashKey: "value" }; moreCode}')
    expect(nodes).to eq [node(:expr_group, content: [
                                node(:expression, content: "thing = { hashKey: \"value\" }; moreCode")
                              ])]
  end

  it "allows for expressions to have arbitrary brackets inside quoted strings" do
    nodes = parse(%({something "quoted {bracket}" '{}' "'{'" more}))
    expect(nodes).to eq [node(:expr_group, content: [
                                node(:expression, content: %(something "quoted {bracket}" '{}' "'{'" more))
                              ])]
  end

  it "doesn't consider escaped quotes to end an expression quoted string" do
    nodes = parse('{"he said \"hello {there}\" loudly"}')
    expect(nodes).to eq [node(:expr_group, content: [
                                node(:expression, content: '"he said \"hello {there}\" loudly"')
                              ])]
  end

  it "parses an expression that starts with a tag" do
    expect(parse("{<h1>Title</h1>}")).to eq [
      node(:expr_group, content: [
             node(:html, name: "h1", void: false, content: [node(:raw, content: "Title")])
           ])
    ]
  end

  it "parses tags within a boolean expression" do
    expect(parse("{true && <h1>Is true</h1>}")).to eq [
      node(:expr_group, content: [
             node(:expression, content: "true && "),
             node(:html, name: "h1", void: false, content: [node(:raw, content: "Is true")])
           ])
    ]
  end

  it "parses self-closing tags within a boolean expression" do
    expect(parse("{true && <br />}")).to eq [
      node(:expr_group, content: [
             node(:expression, content: "true && "),
             node(:html, name: "br", void: true)
           ])
    ]
  end

  it "parses nested tags within a boolean expression" do
    expect(parse("{true && <h1><span>Hey</span></h1>}")).to eq [
      node(:expr_group, content: [
             node(:expression, content: "true && "),
             node(:html, name: "h1", void: false, content: [
                    node(:html, name: "span", void: false, content: [node(:raw, content: "Hey")])
                  ])
           ])
    ]
  end

  it "does not specially tokenize boolean expressions that aren't followed by a tag" do
    expect(parse("{true && 'hey'}")).to eq [
      node(:expr_group, content: [
             node(:expression, content: "true && 'hey'")
           ])
    ]
  end

  it "allows for sub-expressions within a boolean expression tag" do
    expect(parse("{true && <h1>Is {'hello'.upcase}</h1>}")).to eq [
      node(:expr_group, content: [
             node(:expression, content: "true && "),
             node(:html, name: "h1", void: false, content: [
                    node(:raw, content: "Is "),
                    node(:expr_group, content: [
                           node(:expression, content: "'hello'.upcase")
                         ])
                  ])
           ])
    ]
  end

  it "parses tags within a ternary expression" do
    expect(parse("{true ? <h1>Yes</h1> : <h2>No</h2>}")).to eq [
      node(:expr_group, content: [
             node(:expression, content: "true ? "),
             node(:html, name: "h1", void: false, content: [node(:raw, content: "Yes")]),
             node(:expression, content: " : "),
             node(:html, name: "h2", void: false, content: [node(:raw, content: "No")])
           ])
    ]
  end

  it "parses self-closing tags within a ternary expression" do
    expect(parse("{true ? <br /> : <input />}")).to eq [
      node(:expr_group, content: [
             node(:expression, content: "true ? "),
             node(:html, name: "br", void: true),
             node(:expression, content: " : "),
             node(:html, name: "input", void: true)
           ])
    ]
  end

  it "parses tags within a boolean expression including an OR operator" do
    expect(parse("{true || <p>Yes</p>}")).to eq [
      node(:expr_group, content: [
             node(:expression, content: "true || "),
             node(:html, name: "p", void: false, content: [node(:raw, content: "Yes")])
           ])
    ]
  end

  it "parses tags within a do..end block" do
    template = <<~RBX.strip
      {3.times.map do
        <p>Hello</p>
      end}
    RBX
    expect(parse(template)).to eq [
      node(:expr_group, content: [
             node(:expression, content: "3.times.map do\n  "),
             node(:html, name: "p", void: false, content: [node(:raw, content: "Hello")]),
             node(:expression, content: "\nend")
           ])
    ]
  end

  it "parses tags within a do |var|..end block" do
    template = <<~RBX.strip
      {3.times.map do |n|
        <p>Hello</p>
      end}
    RBX
    expect(parse(template)).to eq [
      node(:expr_group, content: [
             node(:expression, content: "3.times.map do |n|\n  "),
             node(:html, name: "p", void: false, content: [node(:raw, content: "Hello")]),
             node(:expression, content: "\nend")
           ])
    ]
  end

  it "parses tags within a {..} block" do
    expect(parse("{3.times.map { <p>Hello</p> }}")).to eq [
      node(:expr_group, content: [
             node(:expression, content: "3.times.map { "),
             node(:html, name: "p", void: false, content: [node(:raw, content: "Hello")]),
             node(:expression, content: " }")
           ])
    ]
  end

  it "parses tags within a {|var|..} block" do
    expect(parse("{3.times.map { |n| <p>Hello</p> }}")).to eq [
      node(:expr_group, content: [
             node(:expression, content: "3.times.map { |n| "),
             node(:html, name: "p", void: false, content: [node(:raw, content: "Hello")]),
             node(:expression, content: " }")
           ])
    ]
  end
end

__END__
