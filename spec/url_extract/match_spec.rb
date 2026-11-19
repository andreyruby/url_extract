# frozen_string_literal: true

RSpec.describe UrlExtract::Match do
  subject { described_class.new("http://a.com/я", 4, "See http://a.com/я") }

  specify "#range" do
    expect(subject.range).to eq 4...18
    expect(subject.text[subject.range]).to eq subject.url
  end

  describe "#==" do
    let(:other_match) { described_class.new(other_url, other_index, other_text) }
    let(:other_url) { "http://a.com/я" }
    let(:other_index) { 4 }
    let(:other_text) { +"See http://a.com/я" }

    it "is true for a match with the same range in an equal text" do
      expect(subject == other_match).to be true
    end

    context "with another text" do
      let(:other_text) { "Get http://a.com/я" }

      it "is false" do
        expect(subject == other_match).to be false
      end
    end

    context "with another index" do
      let(:other_index) { 5 }

      it "is false" do
        expect(subject == other_match).to be false
      end
    end

    context "with a URL of another length" do
      let(:other_url) { "http://a.com/" }

      it "is false" do
        expect(subject == other_match).to be false
      end
    end

    context "with an object that is no match" do
      let(:other_match) { "http://a.com/я" }

      it "is false" do
        expect(subject == other_match).to be false
      end
    end
  end
end
