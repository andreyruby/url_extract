# frozen_string_literal: true

class UrlExtract
  # A URL that the extractor found in a text.
  class Match
    # The URL as the text writes it.
    attr_reader :url
    # The place of the URL in the text, in characters. It replaces the URL: `text[match.range] = '<FILTERED>'`.
    attr_reader :range
    # A frozen copy of the text, as it was when the extractor read it. The matches of one text share it.
    attr_reader :text

    # The extractor makes each match, from the index of the URL in the text.
    def initialize(url, index, text)
      @url = url
      @range = index...(index + url.length)
      @text = text
    end

    # The URL, so `puts match` and `"#{match}"` give it.
    def to_s
      url
    end

    # Shows the URL and the range, and not the text, which can be large.
    def inspect
      "#<#{self.class} url=#{url.inspect} range=#{range.inspect}>"
    end
  end
end
