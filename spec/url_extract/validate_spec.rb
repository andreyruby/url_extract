# frozen_string_literal: true

RSpec.describe UrlExtract::Validate do
  describe ".text" do
    subject { described_class.text(text) }

    context "with a string" do
      let(:text) { "See https://a.com/я" }

      it "takes it" do
        expect { subject }.not_to raise_error
      end
    end

    context "with another encoding, for url_extract/encodings" do
      let(:text) { "https://a.com/я".encode(Encoding::UTF_16LE) }

      it "takes it" do
        expect { subject }.not_to raise_error
      end
    end

    context "with a value that is no string" do
      let(:text) { nil }

      it "raises an error with a hint" do
        expect { subject }.to raise_error TypeError, "Invalid text: nil provided\n[hint] Provide a string"
      end
    end

    context "with an invalid byte" do
      let(:text) { "Я https://a.com/\xFF" }

      it "raises an error that gives the index in characters, with a hint" do
        expect { subject }.to raise_error UrlExtract::EncodingError,
          "Invalid text: can not be read as UTF-8 (encoding UTF-8, index 16)\n[hint] Provide a valid UTF-8 string"
      end
    end

    context "with an invalid byte in another encoding" do
      let(:text) { "h\xD8".dup.force_encoding(Encoding::UTF_16LE) }

      it "raises an error with a hint" do
        expect { subject }.to raise_error UrlExtract::EncodingError, "Invalid text: can not be read as UTF-8 (encoding UTF-16LE, index 0)\n[hint] Provide a valid UTF-8 string"
      end
    end
  end

  describe ".options" do
    def error(options)
      described_class.options(options)
    rescue ArgumentError => e
      e.message
    end

    it "takes the default options" do
      expect { described_class.options(UrlExtract::DEFAULTS) }.not_to raise_error
    end

    it "takes each kind of value" do
      options = {
        prefixes: %w[https:// mailto: www. a.b+c], max_bytesize: nil, trim: ["...", "»"], trim_html_entities: false,
        trim_brackets: false
      }

      expect { described_class.options(options) }.not_to raise_error
    end

    it "raises an error for an unknown option, with the allowed options" do
      hint = "[hint] Allowed options: :prefixes, :max_bytesize, :trim, :trim_html_entities, :trim_brackets, :on_encoding_error"

      expect(error(prefix: %w[www.])).to eq "Unknown option :prefix\n#{hint}"
      expect(error(:format => :html, "tags" => [])).to eq "Unknown options :format, \"tags\"\n#{hint}"
    end

    context "with prefixes" do
      it "raises an error for a value that is no array" do
        expect(error(prefixes: "https://")).to eq "Invalid value for prefixes: \"https://\" provided\n" \
          '[hint] Provide array of strings like ["https://", "http://"]'
      end

      it "cuts a long value" do
        expect(error(prefixes: "a" * 100)).to start_with "Invalid value for prefixes: \"#{"a" * 59}... provided\n"
      end

      it "raises an error for a prefix that is no string, or an empty string" do
        hint = '[hint] Provide a non-empty string like "https://" or "www."'

        expect(error(prefixes: ["https://", :www])).to eq "Invalid prefix: :www provided\n#{hint}"
        expect(error(prefixes: [""])).to eq "Invalid prefix: \"\" provided\n#{hint}"
      end

      it "raises an error for a prefix with an invalid byte or in another encoding" do
        expect(error(prefixes: ["a\xFF://"])).to eq "Invalid prefix: can not be read as UTF-8 (encoding UTF-8, index 1)\n[hint] Provide a valid UTF-8 string"
        expect(error(prefixes: ["магазин.".encode(Encoding::Windows_1251)]))
          .to eq "Invalid prefix: can not be read as UTF-8 (encoding Windows-1251)\n[hint] Provide a valid UTF-8 string"
        expect(error(prefixes: ["https://".encode(Encoding::UTF_16LE)]))
          .to eq "Invalid prefix: can not be read as UTF-8 (encoding UTF-16LE)\n[hint] Provide a valid UTF-8 string"
      end

      it "raises an encoding error, which is an argument error" do
        expect { described_class.options(trim: ["\xFF"]) }.to raise_error(UrlExtract::EncodingError) { |error|
          expect(error).to be_an ArgumentError
        }
      end

      it "takes ASCII characters only in another encoding" do
        expect { described_class.options(prefixes: ["https://".b]) }.not_to raise_error
      end

      it "raises an error for a space" do
        expect(error(prefixes: ["https:// "])).to eq "Invalid prefix: \"https:// \" provided\n[hint] Remove the spaces"
      end

      it "raises an error for a prefix with no \"://\" and no \".\"" do
        expect(error(prefixes: ["https"])).to eq "Invalid prefix: \"https\" provided\n" \
          '[hint] End it with "://" or ".", like "https://" or "www."'
      end
    end

    it "raises an error for a max_bytesize that is no positive integer" do
      hint = "[hint] Provide a positive integer like 8000, or nil for no limit"

      expect(error(max_bytesize: 0)).to eq "Invalid value for max_bytesize: 0 provided\n#{hint}"
      expect(error(max_bytesize: "8000")).to eq "Invalid value for max_bytesize: \"8000\" provided\n#{hint}"
      expect(error(max_bytesize: Float::INFINITY)).to eq "Invalid value for max_bytesize: Infinity provided\n#{hint}"
    end

    context "with trim" do
      it "raises an error for a value that is no array" do
        expect(error(trim: ".")).to eq "Invalid value for trim: \".\" provided\n" \
          '[hint] Provide array of strings like ["?", "!", ".", ",", ":", ";", "*", "_", "~"]'
      end

      it "raises an error for a string that is no string, or an empty string" do
        hint = '[hint] Provide a non-empty string like "."'

        expect(error(trim: [".", 1])).to eq "Invalid trim string: 1 provided\n#{hint}"
        expect(error(trim: [""])).to eq "Invalid trim string: \"\" provided\n#{hint}"
      end
    end

    it "raises an error for a trim_html_entities that is no boolean" do
      expect(error(trim_html_entities: "false"))
        .to eq "Invalid value for trim_html_entities: \"false\" provided\n[hint] Provide true or false"
    end

    it "raises an error for an unknown on_encoding_error" do
      expect(error(on_encoding_error: :ignore))
        .to eq "Invalid value for on_encoding_error: :ignore provided\n[hint] Provide :warn, :skip or :raise"
    end

    it "raises an error for a trim_brackets that is not true or false" do
      expect(error(trim_brackets: "none"))
        .to eq "Invalid value for trim_brackets: \"none\" provided\n[hint] Provide true or false"
    end
  end
end
