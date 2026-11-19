# frozen_string_literal: true

RSpec.describe UrlExtract::BuildRules do
  subject { described_class.call(**UrlExtract::DEFAULTS, **options) }

  let(:options) { {} }

  it "builds the rules" do
    expect(subject).to have_attributes(
      start: %r{https://|http://}i, characters: described_class::CHARACTERS[false],
      max_size: 8000, trim: an_instance_of(UrlExtract::Trim)
    )
  end

  context "with no size limit" do
    let(:options) { {max_size: nil} }

    it "takes each size" do
      expect(subject.max_size).to eq Float::INFINITY
    end
  end

  context "with each kind of scheme, and each set of characters" do
    let(:options) { {schemes: %w[https:// http:// ftp:// www. a.b+c]} }

    it "builds regexps that Ruby runs in linear time" do
      regexps = [subject.start, *described_class::CHARACTERS.values]

      expect(regexps.map { |regexp| Regexp.linear_time?(regexp) }).to all(be true)
    end
  end

  context "with ASCII characters only" do
    let(:options) { {ascii_only: true} }

    it "takes the characters of RFC 3986" do
      expect(subject.characters).to eq described_class::CHARACTERS[true]
    end
  end

  context "with a start that is no scheme" do
    let(:options) { {schemes: %w[www.]} }

    it "builds a start that matches only at the start of a word, before a letter or a digit" do
      expect(subject.start).to eq(/(?<![[:alnum:]])www\.(?=[a-z0-9])/i)
    end
  end

  context "with no scheme" do
    let(:options) { {schemes: []} }

    it "builds no start" do
      expect(subject.start).to be_nil
    end
  end
end
