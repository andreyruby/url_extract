# frozen_string_literal: true

RSpec.describe UrlExtract::Trimming::EndingEntitySize do
  subject { described_class.call(text, start, text.bytesize) }

  let(:start) { 0 }
  let(:text) { "http://a.com/x&quot;" }

  it "returns the count of the bytes of the entity that ends the URL" do
    expect(subject).to eq 6
  end

  context "with an entity of a number" do
    let(:text) { "http://a.com/x&#39;" }

    it "returns the count of its bytes" do
      expect(subject).to eq 5
    end
  end

  context "with an entity of a hexadecimal number" do
    let(:text) { "http://a.com/x&#x27;" }

    it "returns the count of its bytes" do
      expect(subject).to eq 6
    end
  end

  context "with a name of 31 characters" do
    let(:text) { "http://a.com/x&#{"a" * 31};" }

    it "returns the count of the bytes of the entity" do
      expect(subject).to eq 33
    end
  end

  context "with a name of 32 characters" do
    let(:text) { "http://a.com/x&#{"a" * 32};" }

    it "returns 0" do
      expect(subject).to eq 0
    end
  end

  context "with a name of one character" do
    let(:text) { "http://a.com/x&b;" }

    it "returns 0" do
      expect(subject).to eq 0
    end
  end

  context "with a name that starts with a digit" do
    let(:text) { "http://a.com/x&1a;" }

    it "returns 0" do
      expect(subject).to eq 0
    end
  end

  context "with a number sign and no number" do
    let(:text) { "http://a.com/x&#;" }

    it "returns 0" do
      expect(subject).to eq 0
    end
  end

  context "with a number sign and no ampersand" do
    let(:text) { "http://a.com/x#39;" }

    it "returns 0" do
      expect(subject).to eq 0
    end
  end

  context "with a semicolon after a name and no ampersand" do
    let(:text) { "http://a.com/x?quot;" }

    it "returns 0" do
      expect(subject).to eq 0
    end
  end

  context "with no semicolon at the end" do
    let(:text) { "http://a.com/x&quot" }

    it "returns 0" do
      expect(subject).to eq 0
    end
  end

  context "with an ampersand before the start of the URL" do
    let(:text) { "&quot;" }
    let(:start) { 1 }

    it "returns 0" do
      expect(subject).to eq 0
    end
  end

  context "with a number sign at the start of the URL" do
    let(:text) { "&#39;" }
    let(:start) { 1 }

    it "returns 0" do
      expect(subject).to eq 0
    end
  end
end
