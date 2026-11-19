# frozen_string_literal: true

class UrlExtract
  # A URL that the extractor found in a text.
  class Match
    # The URL as the text writes it, and its index in the text, in characters.
    attr_reader :url, :index
    # A frozen copy of the text, as it was when the extractor read it. The matches of one text share it.
    attr_reader :text

    # The extractor makes each match.
    def initialize(url, index, text)
      @url = url
      @index = index
      @text = text
    end

    # Returns the place of the URL in the text. It replaces the URL: `text[match.range] = '<FILTERED>'`.
    def range
      index...(index + url.length)
    end

    # Two matches are equal when they are at the same place of the same text.
    # The texts are equal by their content, so the matches of two extractors of one text are equal.
    def ==(other)
      other.is_a?(self.class) && (range == other.range) && (text == other.text)
    end
  end
end
