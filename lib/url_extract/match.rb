# frozen_string_literal: true

class UrlExtract
  # A URL that the extractor found in a text:
  #
  # ```ruby
  # UrlExtract.scan("See https://a.com/x").first # => #<UrlExtract::Match url="https://a.com/x" range=4...19>
  # ```
  class Match
    # Returns the URL as the text writes it. In HTML it can hold a character reference, such as `&amp;`:
    #
    # ```ruby
    # UrlExtract.scan("See https://a.com/x").first.url                   # => "https://a.com/x"
    # UrlExtract.scan(%(<a href="https://a.com/x?a=1&amp;b=2">)).first.url # => "https://a.com/x?a=1&amp;b=2"
    # ```
    attr_reader :url

    # Returns the place of the URL in the text, in characters:
    #
    # ```ruby
    # match = UrlExtract.scan("See https://a.com/x").first
    # match.range             # => 4...19
    # match.text[match.range] # => "https://a.com/x"
    # ```
    #
    # To replace the URLs of a text, go from the last match to the first: a replacement changes the length
    # of the text, and moves each URL after it:
    #
    # ```ruby
    # text = "See https://a.com/x and https://b.com/y"
    # UrlExtract.scan(text).reverse_each { |match| text[match.range] = "<FILTERED>" }
    # text # => "See <FILTERED> and <FILTERED>"
    # ```
    attr_reader :range

    # Returns a frozen copy of the text, as it was when the extractor read it. The matches of one text share it:
    #
    # ```ruby
    # text = +"See https://a.com/x"
    # match = UrlExtract.scan(text).first
    # text << " More."
    # match.text         # => "See https://a.com/x"
    # match.text.frozen? # => true
    # ```
    attr_reader :text

    # The extractor makes each match, from the index of the URL in the text.
    def initialize(url, index, text)
      @url = url
      @range = index...(index + url.length)
      @text = text
    end

    # call-seq:
    #   to_s -> string
    #
    # Returns the URL:
    #
    # ```ruby
    # match = UrlExtract.scan("See https://a.com/x").first
    # "Link: #{match}" # => "Link: https://a.com/x"
    # ```
    def to_s
      url
    end

    # call-seq:
    #   inspect -> string
    #
    # Returns a string that shows the URL and the range, and not the text, which can be large:
    #
    # ```ruby
    # UrlExtract.scan("See https://a.com/x").first # => #<UrlExtract::Match url="https://a.com/x" range=4...19>
    # ```
    def inspect
      "#<#{self.class} url=#{url.inspect} range=#{range.inspect}>"
    end
  end
end
