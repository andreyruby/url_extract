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
        expect { subject }.to raise_error ArgumentError,
          "Invalid text: can not be read as UTF-8 (encoding UTF-8, index 16)\n[hint] Provide a valid UTF-8 string"
      end
    end

    context "with an invalid byte in another encoding" do
      let(:text) { "h\xD8".dup.force_encoding(Encoding::UTF_16LE) }

      it "raises an error with a hint" do
        expect { subject }.to raise_error ArgumentError, "Invalid text: can not be read as UTF-8 (encoding UTF-16LE, index 0)\n[hint] Provide a valid UTF-8 string"
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
        schemes: %w[https:// mailto: www. a.b+c], max_size: nil, trim: ["...", "»"], trim_html_entities: false,
        trim_brackets: :none
      }

      expect { described_class.options(options) }.not_to raise_error
    end

    it "raises an error for an unknown option, with the allowed options" do
      hint = "[hint] Allowed options: :schemes, :max_size, :trim, :trim_html_entities, :trim_brackets"

      expect(error(scheme: %w[www.])).to eq "Unknown option :scheme\n#{hint}"
      expect(error(:format => :html, "tags" => [])).to eq "Unknown options :format, \"tags\"\n#{hint}"
    end

    context "with schemes" do
      it "raises an error for a value that is no array" do
        expect(error(schemes: "https://")).to eq "Invalid value for schemes: \"https://\" provided\n" \
          '[hint] Provide array of strings like ["https://", "http://"]'
      end

      it "cuts a long value" do
        expect(error(schemes: "a" * 100)).to start_with "Invalid value for schemes: \"#{"a" * 59}... provided\n"
      end

      it "raises an error for a scheme that is no string, or an empty string" do
        hint = '[hint] Provide a non-empty string like "https://" or "www."'

        expect(error(schemes: ["https://", :www])).to eq "Invalid scheme: :www provided\n#{hint}"
        expect(error(schemes: [""])).to eq "Invalid scheme: \"\" provided\n#{hint}"
      end

      it "raises an error for a scheme with an invalid byte or in another encoding" do
        expect(error(schemes: ["a\xFF://"])).to eq "Invalid scheme: can not be read as UTF-8 (encoding UTF-8, index 1)\n[hint] Provide a valid UTF-8 string"
        expect(error(schemes: ["магазин.".encode(Encoding::Windows_1251)]))
          .to eq "Invalid scheme: can not be read as UTF-8 (encoding Windows-1251)\n[hint] Provide a valid UTF-8 string"
        expect(error(schemes: ["https://".encode(Encoding::UTF_16LE)]))
          .to eq "Invalid scheme: can not be read as UTF-8 (encoding UTF-16LE)\n[hint] Provide a valid UTF-8 string"
      end

      it "takes ASCII characters only in another encoding" do
        expect { described_class.options(schemes: ["https://".b]) }.not_to raise_error
      end

      it "raises an error for a space" do
        expect(error(schemes: ["https:// "])).to eq "Invalid scheme: \"https:// \" provided\n[hint] Remove the spaces"
      end

      it "raises an error for a scheme with no \"://\" and no \".\"" do
        expect(error(schemes: ["https"])).to eq "Invalid scheme: \"https\" provided\n" \
          '[hint] End it with "://" or ".", like "https://" or "www."'
      end
    end

    it "raises an error for a max_size that is no positive integer" do
      hint = "[hint] Provide a positive integer like 8000, or nil for no limit"

      expect(error(max_size: 0)).to eq "Invalid value for max_size: 0 provided\n#{hint}"
      expect(error(max_size: "8000")).to eq "Invalid value for max_size: \"8000\" provided\n#{hint}"
      expect(error(max_size: Float::INFINITY)).to eq "Invalid value for max_size: Infinity provided\n#{hint}"
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

    it "raises an error for an unknown trim_brackets" do
      expect(error(trim_brackets: "none"))
        .to eq "Invalid value for trim_brackets: \"none\" provided\n[hint] Provide :unpaired or :none"
    end
  end
end
