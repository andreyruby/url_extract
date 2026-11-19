# frozen_string_literal: true

RSpec.describe UrlExtract::Normalizer do
  subject { described_class.call(raw_url) }

  let(:base_url) { "https://example.com/s/J64P" }
  let(:url) { "#{base_url}?af=1&a=2" }
  let(:raw_url) { url }

  it "returns the URL" do
    expect(subject).to eq url
  end

  context "with HTML character references" do
    let(:raw_url) { "#{base_url}?&#97;&#102;&#61;1&amp;a&equals;2" }

    it "returns the decoded URL" do
      expect(subject).to eq url
    end
  end

  context "with a character reference that has no semicolon" do
    let(:raw_url) { "#{base_url}?&#97f=1&a=2" }

    it "returns the decoded URL" do
      expect(subject).to eq url
    end
  end

  context "with a character reference of a percent sign" do
    let(:raw_url) { "#{base_url}?&#37;61f=1" }

    it "returns the URL with the percent-encoding" do
      expect(subject).to eq "#{base_url}?%61f=1"
    end
  end

  context "with a parameter name that starts as a character reference with no semicolon" do
    let(:raw_url) { "#{base_url}?af=1&copy=2" }

    it "keeps the parameter name" do
      expect(subject).to eq raw_url
    end
  end

  context "with a double quote and an ampersand" do
    let(:raw_url) { %(#{base_url}?a="2"&b=3) }

    it "returns the URL" do
      expect(subject).to eq raw_url
    end
  end

  context "with spaces around the URL" do
    let(:raw_url) { "  #{url} " }

    it "returns the URL without them" do
      expect(subject).to eq url
    end
  end

  context "with control characters" do
    let(:raw_url) { "\x01#{base_url}?a\tf=1&a=2\n" }

    it "returns the URL without them" do
      expect(subject).to eq url
    end
  end

  context "with backslashes before the query" do
    let(:raw_url) { 'https:\\\\example.com\\s\\J64P?af=1&a=\\' }

    it "returns the URL with a slash for each backslash before the query" do
      expect(subject).to eq "#{base_url}?af=1&a=\\"
    end
  end

  context "with a backslash in the fragment" do
    let(:raw_url) { 'https:\\\\example.com/s/J64P#a\\b' }

    it "keeps the backslash of the fragment" do
      expect(subject).to eq "#{base_url}#a\\b"
    end
  end

  context "with a URL that is normalized" do
    let(:raw_url) { base_url }

    it "returns the raw URL itself" do
      expect(subject).to be raw_url
    end
  end
end
