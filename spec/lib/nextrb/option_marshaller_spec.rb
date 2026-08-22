# frozen_string_literal: true

RSpec.describe Nextrb::OptionMarshaller do
  it "sets regular tag arguments" do
    expect(described_class.tag_kwargs({ width: 10 })).to eq 'width="10"'
  end

  it "sets boolean values" do
    expect(described_class.tag_kwargs({ allowfullscreen: true })).to eq "allowfullscreen"
  end

  context "with aria labels" do
    it "sets aria labels as a hash" do
      expect(described_class.tag_kwargs({ aria: { label: "name" } })).to eq 'aria-label="name"'
    end

    it "sets direct aria labels" do
      expect(described_class.tag_kwargs({ "aria-label": "name" })).to eq 'aria-label="name"'
    end

    it "handles aria attributes that are not expected" do
      expect(described_class.tag_kwargs({ aria: { label: { name: true } } })).to eq 'aria-label="{name: true}"'
    end
  end

  context "with data attributes" do
    it "sets data labels as a hash" do
      expect(described_class.tag_kwargs({ data: { url_endpoint: "users" } })).to eq 'data-url-endpoint="users"'
    end

    it "sets data attributes with json if it has a hash value" do
      expect(described_class.tag_kwargs({ data: { user: { name: "bobby" } } })).to(
        eq('data-user="{&quot;name&quot;:&quot;bobby&quot;}"')
      )
    end

    it "sets data attributes with json if it has an array value" do
      expect(described_class.tag_kwargs({ data: { user: %w[bobby tables] } })).to(
        eq('data-user="[&quot;bobby&quot;,&quot;tables&quot;]"')
      )
    end
  end

  context "with class attributes" do
    it "sets class with a single string" do
      expect(described_class.tag_kwargs({ class: "profile" })).to eq 'class="profile"'
    end

    it "sets class with an array" do
      expect(described_class.tag_kwargs({ class: %w[profile red] })).to eq 'class="profile red"'
    end

    it "sets class with a hash of truthy values" do
      expect(described_class.tag_kwargs({ class: { profile: true, red: true,
                                                   green: false } })).to eq 'class="profile red"'
    end
  end

  context "with hx attributes" do
    it "sets hx attributes" do
      expect(described_class.tag_kwargs({ hx: { swap: "#users" } })).to eq 'hx-swap="#users"'
    end
  end
end
