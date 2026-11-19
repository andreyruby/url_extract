# frozen_string_literal: true

RSpec.describe UrlExtract::PairedBracketEnd do
  subject { described_class.call(text, start, text.bytesize) }

  let(:start) { 0 }
  let(:text) { "x_(y)[{1}]" }

  it "returns the byte index after the last closing bracket that has a partner" do
    expect(subject).to eq 10
  end

  context "with no bracket" do
    let(:text) { "x_y" }

    it "returns the start" do
      expect(subject).to eq 0
    end
  end

  context "with a closing bracket that the URL does not open" do
    let(:text) { "x_(y))z" }

    it "returns the index after the closing bracket before it" do
      expect(subject).to eq 5
    end
  end

  context "with an opening bracket that the URL does not close" do
    let(:text) { "x((y)(" }

    it "returns the index after the closing bracket" do
      expect(subject).to eq 5
    end
  end

  context "with a closing bracket before its opening bracket" do
    let(:text) { "x)(" }

    it "returns the start" do
      expect(subject).to eq 0
    end
  end

  context "with a closing bracket of another kind than the open bracket" do
    let(:text) { "x(]}" }

    it "returns the start" do
      expect(subject).to eq 0
    end
  end

  context "with brackets of two kinds that close in the order of their opening" do
    let(:text) { "x[(])" }

    it "returns the index after the last of them" do
      expect(subject).to eq 5
    end
  end

  context "with a URL that starts after a bracket and a character of more than one byte" do
    let(:text) { "(я(x))" }
    let(:start) { 3 }

    it "reads the bytes of the URL only, and returns the index in the text, in bytes" do
      expect(subject).to eq 6
    end
  end
end
