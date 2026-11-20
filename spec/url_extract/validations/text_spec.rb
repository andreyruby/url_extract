# frozen_string_literal: true

RSpec.describe UrlExtract::Validations::Text do
  describe ".check" do
    subject { described_class.check(text) }

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
end
