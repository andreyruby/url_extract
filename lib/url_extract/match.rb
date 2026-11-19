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

    # Two matches are equal when they are at the same place of the same text.
    # The texts are equal by their content, so the matches of two extractors of one text are equal.
    def ==(other)
      other.is_a?(self.class) && (range == other.range) && (text == other.text)
    end
  end
end
