# frozen_string_literal: true

RSpec.describe UrlExtract::Match do
  subject { described_class.new("http://a.com/я", 4, "See http://a.com/я") }

  specify "#range" do
    expect(subject.range).to eq 4...18
    expect(subject.text[subject.range]).to eq subject.url
  end

  specify "#to_s" do
    expect(subject.to_s).to eq "http://a.com/я"
    expect("Open #{subject}").to eq "Open http://a.com/я"
  end

  specify "#inspect" do
    expect(subject.inspect).to eq '#<UrlExtract::Match url="http://a.com/я" range=4...18>'
  end
end
