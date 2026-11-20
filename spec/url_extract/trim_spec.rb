# frozen_string_literal: true

RSpec.describe UrlExtract::Trim do
  subject { url.byteslice(0, kept_size) }

  # The URL starts at byte 5 of the text, after a character of two bytes.
  let(:text) { "я, #{url} and more" }
  let(:kept_size) { described_class.new(trim:, trim_html_entities:, trim_brackets:).call(text, 4, url.bytesize) }

  let(:trim) { UrlExtract::TRIM }
  let(:trim_html_entities) { true }
  let(:trim_brackets) { true }
  let(:url) { "http://a.com/x/" }

  it "returns the URL" do
    expect(subject).to eq url
  end

  context "with strings of the list at the end" do
    let(:url) { "http://a.com/x?a=1.,:;!?*_~..." }

    it "removes them" do
      expect(subject).to eq "http://a.com/x?a=1"
    end
  end

  context "with a character that the list does not hold at the end" do
    let(:url) { %(http://a.com/x') }

    it "returns the URL" do
      expect(subject).to eq url
    end
  end

  context "with HTML entities at the end" do
    let(:url) { "http://a.com/x?a=1&amp;b=2&quot;.&hl;&#39;&hellip;&#x27;" }

    it "removes them, and keeps an entity inside the URL" do
      expect(subject).to eq "http://a.com/x?a=1&amp;b=2"
    end

    context "with no trim of the entities" do
      let(:trim_html_entities) { false }

      it "returns the URL, with the semicolon of the last entity" do
        expect(subject).to eq url
      end
    end
  end

  context "with a string of the list after an HTML entity, and no trim of the entities" do
    let(:trim_html_entities) { false }
    let(:url) { "http://a.com/x&quot;.;" }

    it "removes the string, and keeps the entity" do
      expect(subject).to eq "http://a.com/x&quot;"
    end
  end

  context "with an HTML entity after a character of more than one byte" do
    let(:url) { "http://a.com/#{"я" * 20}&quot;" }

    it "removes the entity" do
      expect(subject).to eq "http://a.com/#{"я" * 20}"
    end
  end

  context "with a semicolon at the end that ends no HTML entity" do
    let(:url) { "http://a.com/x;a=1&b;" }

    it "removes the semicolon only" do
      expect(subject).to eq "http://a.com/x;a=1&b"
    end
  end

  context "with strings of more than one byte in the list" do
    let(:trim) { %w[... . »] }
    let(:url) { "http://a.com/я....»" }

    it "removes them" do
      expect(subject).to eq "http://a.com/я"
    end
  end

  context "with closing brackets that the URL does not open" do
    let(:url) { "http://a.com/x_(y)[1]{2}).]}.)" }

    it "removes them, and keeps each bracket that the URL opens" do
      expect(subject).to eq "http://a.com/x_(y)[1]{2}"
    end

    context "with no trim of the brackets" do
      let(:trim_brackets) { false }

      it "removes the strings of the list up to the last bracket" do
        expect(subject).to eq "http://a.com/x_(y)[1]{2}).]}.)"
      end
    end
  end

  context "with a closing bracket inside the URL that the URL does not open" do
    let(:url) { "http://a.com/x_(y))+ok" }

    it "returns the URL" do
      expect(subject).to eq url
    end
  end

  context "with a closing bracket of another kind than the opening bracket" do
    let(:url) { "http://a.com/x_(y]" }

    it "removes the closing bracket" do
      expect(subject).to eq "http://a.com/x_(y"
    end
  end

  context "with opening brackets at the end that the URL does not close" do
    let(:url) { "http://a.com/x_(y)[.{(" }

    it "removes them, and keeps each bracket that the URL closes" do
      expect(subject).to eq "http://a.com/x_(y)"
    end
  end

  context "with a closing bracket before its opening bracket" do
    let(:url) { "http://a.com/x)(" }

    it "removes both, because neither has a partner" do
      expect(subject).to eq "http://a.com/x"
    end
  end

  context "with brackets inside brackets" do
    let(:url) { "http://a.com/x({[1]})" }

    it "returns the URL" do
      expect(subject).to eq url
    end
  end

  context "with an opening bracket inside the URL that the URL does not close" do
    let(:url) { "http://a.com/x(y" }

    it "returns the URL" do
      expect(subject).to eq url
    end
  end

  context "with only strings of the list" do
    let(:url) { "..." }

    it "returns an empty string" do
      expect(subject).to eq ""
    end
  end

  context "with an empty list and no trim of the brackets" do
    let(:trim) { [] }
    let(:trim_brackets) { false }
    let(:url) { "http://a.com/x)." }

    it "returns the URL" do
      expect(subject).to eq url
    end
  end
end
