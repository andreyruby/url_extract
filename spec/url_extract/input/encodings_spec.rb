# frozen_string_literal: true

require "open3"
require "url_extract/encodings"

RSpec.describe UrlExtract::Input::Encodings do
  def matches(text, **options)
    UrlExtract.new(text, **options).to_a
  end

  it "is not loaded by default, and loads at the first text in another encoding" do
    script = <<~RUBY
      require "url_extract"
      loaded = -> { $LOADED_FEATURES.any? { |path| path.end_with?("/url_extract/input/encodings.rb") } }
      UrlExtract.scan("See https://a.com/я").to_a
      UrlExtract.scan("See https://a.com/x".b).to_a
      print loaded.call
      UrlExtract.scan("See https://a.com/я".encode(Encoding::Windows_1251)).to_a
      print " ", loaded.call
    RUBY
    output, status = Open3.capture2e(RbConfig.ruby, "-I", File.expand_path("../../lib", __dir__), "-e", script)

    expect([output, status.success?]).to eq ["false true", true]
  end

  {
    "Windows-1251" => "Привет, https://a.com/путь. и (http://b.com/я)",
    "KOI8-R" => "Привет, https://a.com/путь. и (http://b.com/я)",
    "ISO-8859-1" => "Café, https://a.com/été. et (http://b.com/à)",
    "Shift_JIS" => "見て、https://a.com/表. と (http://b.com/兩)",
    "GB18030" => "看看，https://a.com/路径. 和 (http://b.com/乢)",
    "Big5" => "看看，https://a.com/路徑. 和 (http://b.com/于)",
    "UTF-16LE" => "Привет, https://a.com/путь. и (http://b.com/я)",
    "UTF-32BE" => "見て、https://a.com/表. と (http://b.com/兩)"
  }.each do |encoding, utf8_text|
    context "with #{encoding}" do
      let(:text) { utf8_text.encode(encoding) }

      it "finds the URLs of the UTF-8 text, in the encoding of the text, at the same ranges" do
        found = matches(text)
        expected = matches(utf8_text)

        expect(found.map { |match| match.url.encode(Encoding::UTF_8) }).to eq expected.map(&:url)
        expect(found.map(&:range)).to eq expected.map(&:range)
        expect(found.map { |match| match.url.encoding }).to all eq Encoding.find(encoding)
        expect(found.map { |match| text[match.range] }).to eq found.map(&:url)
      end
    end
  end

  context "with the options" do
    let(:text) { "См. www.a.com/путь» и https://b.com".encode(Encoding::Windows_1251) }

    it "compares the strings of the options with the characters of the text" do
      urls = matches(text, prefixes: %w[www.], trim: %w[»]).map { |match| match.url.encode(Encoding::UTF_8) }

      expect(urls).to eq ["www.a.com/путь"]
    end
  end

  context "with a frozen text" do
    let(:text) { "See https://a.com/я".encode(Encoding::Windows_1251).freeze }

    it "gives the text to each match" do
      expect(matches(text).first.text).to equal text
    end
  end

  context "with a text that it can not read, with the default on_encoding_error" do
    let(:text) { "https://a.com/\xFF".b }

    it "warns and gives no match" do
      expect { expect(matches(text)).to eq [] }.to output(
        /encodings_spec\.rb:\d+: warning: url_extract: Invalid text: can not be read as UTF-8 \(encoding ASCII-8BIT/
      ).to_stderr
    end
  end

  context "with a string of bytes that are not ASCII" do
    let(:text) { "https://a.com/\xFF".b }

    it "raises an error with the index of the first byte that is not ASCII" do
      expect { matches(text, on_encoding_error: :raise) }.to raise_error UrlExtract::EncodingError,
        "Invalid text: can not be read as UTF-8 (encoding ASCII-8BIT, index 14)\n[hint] Provide a valid UTF-8 string"
    end
  end

  context "with a dummy encoding" do
    let(:text) { "https://a.com/見".encode(Encoding::ISO_2022_JP) }

    it "raises an error" do
      expect { matches(text, on_encoding_error: :raise) }.to raise_error UrlExtract::EncodingError,
        "Invalid text: can not be read as UTF-8 (encoding ISO-2022-JP)\n[hint] Provide a valid UTF-8 string"
    end
  end

  context "with an encoding that Ruby can not convert to UTF-8" do
    let(:text) { "https://a.com/\xA4\xA1".dup.force_encoding(Encoding::EUC_TW) }

    it "raises an error" do
      expect { matches(text, on_encoding_error: :raise) }.to raise_error UrlExtract::EncodingError, "Invalid text: can not be read as UTF-8 (encoding EUC-TW)\n[hint] Provide a valid UTF-8 string"
    end
  end

  context "with a character that has no Unicode form" do
    let(:text) { "Я https://a.com/".encode(Encoding::Windows_1251) + "\x98".dup.force_encoding(Encoding::Windows_1251) }

    it "raises an error with the index of the character" do
      expect { matches(text, on_encoding_error: :raise) }.to raise_error UrlExtract::EncodingError,
        "Invalid text: can not be read as UTF-8 (encoding Windows-1251, index 16)\n[hint] Provide a valid UTF-8 string"
    end
  end
end
