# frozen_string_literal: true

RSpec.describe UrlExtract::Finder do
  subject { described_class.new(text, **options) }

  let(:options) { {} }
  let(:text) { "See https://a.com/x or http://b.com/y" }

  it "gives each URL with its index and its range" do
    expect(subject.to_a).to match [
      have_attributes(url: "https://a.com/x", index: 4, range: 4...19),
      have_attributes(url: "http://b.com/y", index: 23, range: 23...37)
    ]
  end

  it "gives a range that replaces the URL in the text" do
    replaced_text = text.dup
    subject.reverse_each { |match| replaced_text[match.range] = "URL" }

    expect(replaced_text).to eq "See URL or URL"
  end

  context "with characters of more than one byte" do
    let(:text) { "Привет, https://a.com/я и http://b.com/y" }

    it "gives the index of each URL in characters" do
      expect(subject.to_a).to match [
        have_attributes(url: "https://a.com/я", index: 8, range: 8...23),
        have_attributes(url: "http://b.com/y", index: 26, range: 26...40)
      ]
    end
  end

  context "with a dot after a URL" do
    let(:text) { "See https://a.com/x." }

    it "gives the URL with no dot" do
      expect(subject.map(&:url)).to eq %w[https://a.com/x]
    end
  end

  context "with brackets around a URL" do
    let(:text) { "See (https://a.com/x_(y))" }

    it "gives the URL with its own brackets only" do
      expect(subject.map(&:url)).to eq %w[https://a.com/x_(y)]
    end
  end

  context "with an HTML entity after a URL" do
    let(:text) { "See &quot;https://a.com/x&quot;" }

    it "gives the URL with no entity" do
      expect(subject.map(&:url)).to eq %w[https://a.com/x]
    end
  end

  describe "#each" do
    let(:yielded_urls) { [] }

    it "gives each match to the block in the order of the text, and returns the finder" do
      expect(subject.each { |match| yielded_urls << match.url }).to be subject
      expect(yielded_urls).to eq %w[https://a.com/x http://b.com/y]
    end

    context "with no block" do
      it "returns an enumerator of the matches" do
        expect(subject.each).to be_an(Enumerator)
        expect(subject.each.map(&:url)).to eq %w[https://a.com/x http://b.com/y]
      end
    end
  end

  context "with a part of the matches" do
    let(:text) { "http://a.com/x http://b.com/y" }

    before { allow(UrlExtract::Match).to receive(:new).and_call_original }

    it "finds no match after the last match that the caller takes" do
      expect(subject.first(1).map(&:url)).to eq %w[http://a.com/x]

      expect(UrlExtract::Match).to have_received(:new).once.with("http://a.com/x", 0, text)
    end
  end

  context "with no URL in the text" do
    let(:text) { "Привет" }

    it "gives no match" do
      expect(subject.first).to be_nil
    end
  end

  context "with a text that changes after the finder gets it" do
    let(:text) { +"See http://a.com/x and http://b.com/y" }

    it "gives each match one frozen copy of the text, as the finder got it" do
      finder = subject
      text.clear
      matches = finder.to_a

      expect(matches.map(&:text)).to all(eq("See http://a.com/x and http://b.com/y").and(be_frozen))
      expect(matches.first.text).to be matches.last.text
    end
  end

  context "with a frozen text" do
    let(:text) { "Привет, http://a.com/x" }

    it "gives each match the text itself" do
      expect(subject.first.text).to be text
    end
  end

  context "with the default options" do
    let(:options) { {} }

    before { allow(UrlExtract::BuildRules).to receive(:call) }

    it "uses the rules that the class built when it loaded" do
      expect(subject.map(&:url)).to eq %w[https://a.com/x http://b.com/y]

      expect(UrlExtract::BuildRules).not_to have_received(:call)
    end
  end

  context "with options" do
    let(:options) { {schemes: %w[www.], trim: %w[,], trim_brackets: :none} }
    let(:text) { "See (www.a.com/x), or http://b.com." }

    it "finds the URLs by the options" do
      expect(subject.to_a).to match [have_attributes(url: "www.a.com/x)", index: 5)]
    end

    it "builds the rules of the options one time" do
      allow(UrlExtract::BuildRules).to receive(:call).and_call_original
      first_options = {schemes: %w[http://], trim: %w[!]}
      second_options = {schemes: %w[http://], trim: %w[!]}

      described_class.new(text, **first_options)
      described_class.new("http://a.com", **second_options)

      expect(UrlExtract::BuildRules).to have_received(:call).once
    end
  end

  # The numbers are the numbers of the examples in the "Autolinks (extension)" part of the spec.
  context "with the examples of the GitHub Flavored Markdown Spec" do
    let(:options) { {schemes: %w[https:// http:// www.]} }
    let(:bracket_url) { "www.google.com/search?q=Markup+(business)" }

    {
      622 => ["www.commonmark.org", %w[www.commonmark.org]],
      623 => ["Visit www.commonmark.org/help for more information.", %w[www.commonmark.org/help]],
      624 => [
        "Visit www.commonmark.org.\n\nVisit www.commonmark.org/a.b.", %w[www.commonmark.org www.commonmark.org/a.b]
      ],
      626 => ["www.google.com/search?q=(business))+ok", %w[www.google.com/search?q=(business))+ok]],
      627 => [
        "www.google.com/search?q=commonmark&hl=en\n\nwww.google.com/search?q=commonmark&hl;",
        %w[www.google.com/search?q=commonmark&hl=en www.google.com/search?q=commonmark]
      ],
      628 => ["www.commonmark.org/he<lp", %w[www.commonmark.org/he]],
      629 => [
        "http://commonmark.org\n\n(Visit https://encrypted.google.com/search?q=Markup+(business))",
        %w[http://commonmark.org https://encrypted.google.com/search?q=Markup+(business)]
      ]
    }.each do |number, (example_text, urls)|
      context "with example #{number}" do
        let(:text) { example_text }

        it "finds the links of the example" do
          expect(subject.map(&:url)).to eq urls
        end
      end
    end

    context "with example 625" do
      let(:text) { "#{bracket_url}\n\n#{bracket_url}))\n\n(#{bracket_url})\n\n(#{bracket_url}" }

      it "finds the links of the example" do
        expect(subject.map(&:url)).to eq [bracket_url] * 4
      end
    end
  end

  context "with the schemes option" do
    let(:text) { "http://a.com HTTPS://b.com ftp://c.com www.d.com xwww.e.com" }

    context "with the default schemes" do
      let(:options) { {} }

      it "finds each http and https URL, in each letter case" do
        expect(subject.map(&:url)).to eq %w[http://a.com HTTPS://b.com]
      end
    end

    context "with another scheme" do
      let(:options) { {schemes: %w[ftp://]} }

      it "finds the URLs of that scheme only" do
        expect(subject.map(&:url)).to eq %w[ftp://c.com]
      end
    end

    context "with a start that is no scheme" do
      let(:options) { {schemes: %w[www.]} }

      it "finds it at the start of a word only" do
        expect(subject.map(&:url)).to eq %w[www.d.com]
      end
    end

    context "with no scheme" do
      let(:options) { {schemes: []} }

      it "gives no match" do
        expect(subject.to_a).to eq []
      end
    end
  end

  context "with characters that are not ASCII" do
    let(:text) { "http://a.com/путь?я=1 http://b.com/x\xC2\xA0y" }

    it "takes a character that is not ASCII, and ends the URL before a space that is not ASCII" do
      expect(subject.map(&:url)).to eq %w[http://a.com/путь?я=1 http://b.com/x]
    end
  end

  context "with the removed ascii_only option" do
    let(:options) { {ascii_only: true} }

    it "raises an error" do
      expect { subject }.to raise_error ArgumentError, /\AUnknown option :ascii_only\n\[hint\] Allowed options: /
    end
  end

  context "with the max_size option" do
    let(:text) { "See #{url}." }
    let(:url) { "http://a.com/#{"x" * path_size}" }

    context "with the default limit and a URL of 8000 bytes" do
      let(:options) { {} }
      let(:path_size) { 7_987 }

      it "gives the URL" do
        expect(subject.map(&:url)).to eq [url]
      end
    end

    context "with the default limit and a URL of 8001 bytes" do
      let(:options) { {} }
      let(:path_size) { 7_988 }

      it "gives no match" do
        expect(subject.to_a).to eq []
      end
    end

    context "with a larger limit and a URL of 8001 bytes" do
      let(:options) { {max_size: 8_001} }
      let(:path_size) { 7_988 }

      it "gives the URL" do
        expect(subject.map(&:url)).to eq [url]
      end
    end

    context "with no limit" do
      let(:options) { {max_size: nil} }
      let(:path_size) { 100_000 }

      it "gives a URL of each size" do
        expect(subject.map(&:url)).to eq [url]
      end
    end

    context "with a smaller limit" do
      let(:options) { {max_size: 14} }
      let(:text) { "http://a.com/x. http://a.com/xy?u=http://b.com http://c.com" }

      it "counts the size after the trim, and gives no match for a part of a longer URL" do
        expect(subject.map(&:url)).to eq %w[http://a.com/x http://c.com]
      end
    end

    context "with a URL of characters of more than one byte" do
      let(:options) { {max_size: 14} }
      let(:text) { "http://a.com/я http://a.com/x" }

      it "counts the bytes of the URL" do
        expect(subject.map(&:url)).to eq %w[http://a.com/x]
      end
    end
  end

  context "with the trim option" do
    context "with the default list" do
      let(:options) { {} }

      let(:text) do
        "http://a.com/a? http://a.com/b! http://a.com/c. http://a.com/d, http://a.com/e: http://a.com/f; " \
          "http://a.com/g* http://a.com/h_ http://a.com/i~ http://a.com/j?!.. http://a.com/k.l?m=n_o~p"
      end

      it "removes each string of the list from the end of a URL, and none from its middle" do
        expect(subject.map(&:url)).to eq %w[
          http://a.com/a http://a.com/b http://a.com/c http://a.com/d http://a.com/e http://a.com/f
          http://a.com/g http://a.com/h http://a.com/i http://a.com/j http://a.com/k.l?m=n_o~p
        ]
      end
    end

    context "with another list" do
      let(:options) { {trim: %w[! ...]} }
      let(:text) { "http://a.com/x.! http://a.com/y... http://a.com/z.." }

      it "removes the strings of that list only" do
        expect(subject.map(&:url)).to eq %w[http://a.com/x. http://a.com/y http://a.com/z..]
      end
    end

    context "with an empty list" do
      let(:options) { {trim: []} }
      let(:text) { "http://a.com/x." }

      it "removes nothing" do
        expect(subject.map(&:url)).to eq %w[http://a.com/x.]
      end
    end

    context "with a value that is no array" do
      let(:options) { {trim: "."} }

      it "raises an error" do
        expect { subject }.to raise_error ArgumentError, /\AInvalid value for trim: "\." provided\n\[hint\] /
      end
    end
  end

  context "with the trim_html_entities option" do
    let(:text) { "http://a.com/a&quot; http://a.com/b&#39; http://a.com/c&#x27; http://a.com/d?e=1&amp;f=2" }

    context "with true, the default" do
      let(:options) { {} }

      it "removes an HTML entity from the end of a URL, and none from its middle" do
        expect(subject.map(&:url)).to eq %w[http://a.com/a http://a.com/b http://a.com/c http://a.com/d?e=1&amp;f=2]
      end
    end

    context "with false" do
      let(:options) { {trim_html_entities: false} }

      it "keeps each HTML entity whole, with its last character" do
        expect(subject.map(&:url)).to eq %w[
          http://a.com/a&quot; http://a.com/b&#39; http://a.com/c&#x27; http://a.com/d?e=1&amp;f=2
        ]
      end
    end
  end

  context "with the trim_brackets option" do
    let(:text) { "(http://a.com/a) http://a.com/b_(c) http://a.com/d( [http://a.com/e]. http://a.com/f[1]" }

    context "with :unpaired, the default" do
      let(:options) { {} }

      it "removes each bracket with no partner from the end of a URL, and keeps a bracket with a partner" do
        expect(subject.map(&:url)).to eq [
          "http://a.com/a", "http://a.com/b_(c)", "http://a.com/d", "http://a.com/e", "http://a.com/f[1]"
        ]
      end
    end

    context "with :none" do
      let(:options) { {trim_brackets: :none} }

      it "keeps each bracket" do
        expect(subject.map(&:url)).to eq [
          "http://a.com/a)", "http://a.com/b_(c)", "http://a.com/d(", "http://a.com/e]", "http://a.com/f[1]"
        ]
      end
    end

    context "with an unknown value" do
      let(:options) { {trim_brackets: :all} }

      it "raises an error" do
        expect { subject }.to raise_error ArgumentError, /\AInvalid value for trim_brackets: :all provided\n/
      end
    end
  end

  context "with ASCII characters only, in another encoding" do
    let(:text) { "See https://a.com/x.".b }

    it "gives each URL in the encoding of the text" do
      expect(subject.map(&:url)).to eq ["https://a.com/x".b]
      expect(subject.first.url.encoding).to eq Encoding::BINARY
    end
  end

  context "with another encoding" do
    let(:text) { "Я https://a.com/я.".encode(Encoding::Windows_1251) }

    it "gives each URL in the encoding of the text, with its index in the text" do
      expect(subject.to_a).to match [have_attributes(url: "https://a.com/я".encode(Encoding::Windows_1251), index: 2)]
    end
  end

  context "with an invalid byte" do
    let(:text) { "http://a.com/x \xFF" }

    it "raises an error when the finder is made" do
      expect { subject }.to raise_error ArgumentError, /\AInvalid text: can not be read as UTF-8 \(encoding UTF-8, index 15\)\n/
    end
  end

  context "with an unknown option" do
    let(:options) { {format: :html, tags: %w[a]} }

    it "raises an error" do
      expect { subject }.to raise_error ArgumentError, /\AUnknown options :format, :tags\n/
    end
  end
end
