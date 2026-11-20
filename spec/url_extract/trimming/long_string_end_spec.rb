# frozen_string_literal: true

RSpec.describe UrlExtract::Trimming::LongStringEnd do
  subject { described_class.new(strings).call(text, 0, text.bytesize) }

  let(:strings) { %w[... »] }
  let(:text) { "http://a.com/x..." }

  it "returns the count of the bytes of the string that ends the URL" do
    expect(subject).to eq 3
  end

  context "with a string of one character of two bytes" do
    let(:text) { "http://a.com/x»" }

    it "returns the count of its bytes" do
      expect(subject).to eq 2
    end
  end

  context "with the last byte of a string, and no string at the end" do
    let(:text) { "http://a.com/x.." }

    it "returns 0" do
      expect(subject).to eq 0
    end
  end

  context "with another last byte" do
    let(:text) { "http://a.com/x" }

    it "returns 0" do
      expect(subject).to eq 0
    end
  end

  context "with no string" do
    let(:strings) { [] }

    it "returns 0" do
      expect(subject).to eq 0
    end
  end

  context "with a URL that is shorter than a string" do
    subject { described_class.new(strings).call(text, text.bytesize - 2, text.bytesize) }

    let(:text) { "..." }

    it "returns 0" do
      expect(subject).to eq 0
    end
  end
end
