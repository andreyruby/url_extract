# frozen_string_literal: true

RSpec.describe UrlExtract::Rules do
  subject { described_class.build(**UrlExtract::DEFAULTS, **options) }

  let(:options) { {} }

  it "builds the rules" do
    expect(subject).to have_attributes(
      start: %r{https://|http://}i, max_bytesize: 8000, trim: an_instance_of(UrlExtract::Trimming::Trim)
    )
  end

  context "with no size limit" do
    let(:options) { {max_bytesize: nil} }

    it "takes each size" do
      expect(subject.max_bytesize).to eq Float::INFINITY
    end
  end

  context "with each kind of prefix" do
    let(:options) { {prefixes: %w[https:// http:// ftp:// www. a.b+c]} }

    it "builds a start that Ruby runs in linear time" do
      expect(Regexp.linear_time?(subject.start)).to be true
    end
  end

  context "with a start that is no prefix" do
    let(:options) { {prefixes: %w[www.]} }

    it "builds a start that matches only at the start of a word, before a letter or a digit" do
      expect(subject.start).to eq(/(?<![[:alnum:]])www\.(?=[a-z0-9])/i)
    end
  end

  context "with no prefix" do
    let(:options) { {prefixes: []} }

    it "builds no start" do
      expect(subject.start).to be_nil
    end
  end
end
