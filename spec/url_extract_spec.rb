# frozen_string_literal: true

RSpec.describe UrlExtract do
  let(:text) { "See https://a.com/x. Then www.b.com/y" }

  it "has a version number" do
    expect(UrlExtract::VERSION).not_to be_nil
  end

  describe ".urls" do
    it "returns the URLs of the text" do
      expect(described_class.urls(text)).to eq ["https://a.com/x"]
    end

    it "takes the options of the extractor" do
      expect(described_class.urls(text, schemes: %w[https:// www.])).to eq ["https://a.com/x", "www.b.com/y"]
    end
  end

  describe ".matches" do
    it "returns an extractor of the matches" do
      expect(described_class.matches(text)).to be_a(UrlExtract::Extractor)
      expect(described_class.matches(text).to_a).to match [have_attributes(url: "https://a.com/x", index: 4)]
    end
  end
end
