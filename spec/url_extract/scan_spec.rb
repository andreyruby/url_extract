# frozen_string_literal: true

RSpec.describe UrlExtract::Scan do
  # Each URL that the scan gives to its block, with its byte index.
  subject { [].tap { |found| described_class.new(text, rules).call { |url, byte_index| found << [url, byte_index] } } }

  let(:rules) { UrlExtract::BuildRules.call(**UrlExtract::DEFAULTS, **options) }
  let(:options) { {trim: [], trim_html_entities: false, trim_brackets: false} }
  let(:text) { "Get http://a.com/x or HTTPS://B.com/y?z=1#top. Then ftp://c.com and www.d.com" }

  it "finds each http and https URL with its byte index" do
    expect(subject).to eq [["http://a.com/x", 4], ["HTTPS://B.com/y?z=1#top.", 22]]
  end

  context "with a character of more than one byte before a URL" do
    let(:text) { "я http://a.com/я" }

    it "gives the index in bytes" do
      expect(subject).to eq [["http://a.com/я", 3]]
    end
  end

  context "with a scheme inside a word" do
    let(:text) { "xhttp://a.com/x" }

    it "finds the URL" do
      expect(subject).to eq [["http://a.com/x", 1]]
    end
  end

  context "with a scheme and nothing after it" do
    let(:text) { "See http:// and https://" }

    it "finds no URL" do
      expect(subject).to eq []
    end
  end

  context "with a URL that holds another URL" do
    let(:text) { "http://a.com/x?u=http://b.com/y" }

    it "finds one URL" do
      expect(subject).to eq [["http://a.com/x?u=http://b.com/y", 0]]
    end
  end

  context "with a character after a URL that is no URL character" do
    let(:text) { %(http://a.com/1"http://b.com/2 http://a.com/3|x http://a.com/путь\u00A0x http://a.com/4<b>) }

    it "ends the URL before it, and takes a character that is not ASCII and not a space" do
      expect(subject.map(&:first)).to eq %w[http://a.com/1 http://b.com/2 http://a.com/3 http://a.com/путь http://a.com/4]
    end

    context "with a text of ASCII characters only" do
      let(:text) { %(http://a.com/1"http://b.com/2 http://a.com/3|x http://a.com/4<b>) }

      it "ends the URL before it" do
        expect(subject.map(&:first)).to eq %w[http://a.com/1 http://b.com/2 http://a.com/3 http://a.com/4]
      end
    end
  end

  context "with other prefixes" do
    let(:options) { {prefixes: %w[ftp:// www.], trim: [], trim_brackets: false} }
    let(:text) { "http://a.com sftp://b.com www.c.com (WWW.d.com) xwww.e.com яwww.f.com «www.g.com www. www.-" }

    it "finds a prefix with \"://\" at each place, and another start only at the start of a word" do
      expect(subject.map(&:first)).to eq %w[ftp://b.com www.c.com WWW.d.com) www.g.com]
    end
  end

  context "with no prefix" do
    let(:options) { {prefixes: []} }

    it "finds no URL" do
      expect(subject).to eq []
    end
  end

  context "with a trim" do
    let(:options) { {} }
    let(:text) { "See (http://a.com/x_(y)), http://a.com/z. And http://a.com/q&amp;" }

    it "removes the end of each URL that belongs to the text, and goes on after the URL" do
      expect(subject).to eq [["http://a.com/x_(y)", 5], ["http://a.com/z", 26], ["http://a.com/q", 46]]
    end
  end

  context "with a size limit" do
    let(:options) { {max_bytesize: 14} }
    let(:text) { "http://a.com/x. http://a.com/xy?u=http://b.com http://c.com" }

    it "finds each URL of that size or less after the trim, and no part of a longer URL" do
      expect(subject).to eq [["http://a.com/x", 0], ["http://c.com", 47]]
    end

    context "with no limit" do
      let(:options) { {max_bytesize: nil} }
      let(:text) { "http://a.com/#{"x" * 9_000}" }

      it "finds a URL of each size" do
        expect(subject).to eq [[text, 0]]
      end
    end
  end

  context "with HTML" do
    let(:text) { '<a href="http://a.com/1?b=2&amp;c=3">http://a.com/2</a> <a href="/relative">x</a>' }

    it "finds each URL that starts with a scheme, and no relative URL" do
      expect(subject).to eq [["http://a.com/1?b=2&amp;c=3", 9], ["http://a.com/2", 37]]
    end
  end

  context "with a trim that removes each character after each scheme" do
    let(:options) { {trim: %w[h t p : /]} }
    let(:text) { "http://" * 60_000 }

    it "finds no URL in a short time", :aggregate_failures do
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      expect(subject).to eq []
      expect(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at).to be < 1
    end
  end

  context "with a text that takes Rinku a time that grows with the square of its length" do
    let(:options) { {prefixes: %w[https:// http:// ftp:// www.]} }
    let(:text) { "x://a.b" * 60_000 }

    it "finds no URL in a short time", :aggregate_failures do
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      expect(subject).to eq []
      expect(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at).to be < 1
    end
  end

  it "uses regexps of the characters that Ruby runs in linear time" do
    regexps = [described_class::CHARACTERS, described_class::ASCII_CHARACTERS]

    expect(regexps.map { |regexp| Regexp.linear_time?(regexp) }).to all(be true)
  end
end
