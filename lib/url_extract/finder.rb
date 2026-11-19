# frozen_string_literal: true

module UrlExtract
  # Finds each URL in a text.
  #
  #   match = UrlExtract::Finder.new('See https://a.com/x.').first
  #   match.url   # => "https://a.com/x"
  #   match.index # => 4
  #   match.range # => 4...19
  #
  # A finder is enumerable:
  #
  #   finder = UrlExtract::Finder.new(text, schemes: %w[https:// http:// www.])
  #
  #   finder.each { |match| puts match.url } # each match, when the finder finds it
  #   finder.to_a                            # the list of the matches
  #   finder.first(3)                        # the first 3 matches: it reads the text up to the third
  #   finder.map(&:url)
  #
  # The class builds the rules of each set of options one time, so a new finder for each text costs little.
  #
  # A match has:
  # - url: the URL as the text writes it. In HTML it can hold a character reference, such as `&amp;`.
  # - index: the index of the URL in the text, in characters.
  # - text: a frozen copy of the text, as it was when the finder read it.
  # - range: the place of the URL in the text. It replaces the URL:
  #
  #     text[match.range] = '<FILTERED>'
  #
  #   To replace more than one URL, go from the last match to the first, as `reverse_each` does.
  #   A replacement moves the URLs after it.
  #
  # The text is a plain text: the finder reads no tag. In HTML it finds a URL that starts with a scheme,
  # also in an attribute, and it does not find a relative URL, such as `href="/path"`.
  #
  # The options:
  # - schemes: what starts a URL. A scheme with `://` starts a URL at each place.
  #   Another start, such as `www.`, starts a URL only at the start of a word, before a letter or a digit.
  # - max_size: the largest size of a URL, in bytes. The finder gives no match for a longer URL,
  #   and no match for a part of it. `nil` sets no limit.
  # - trim: the strings to remove from the end of a URL, as `See https://a.com/x.` needs. `[]` removes nothing.
  # - trim_html_entities: `true` removes an HTML entity from the end of a URL, such as `&quot;`, `&#39;`
  #   or `&#x27;`. `false` keeps it. An entity is one unit: the `;` of the `trim` list does not cut its end.
  # - trim_brackets: `:unpaired` removes from the end of a URL a closing bracket that the URL
  #   does not open, and an opening bracket that the URL does not close. `:none` removes no bracket.
  #
  # A URL holds the characters of RFC 3986, and each character that is not ASCII and not a space,
  # as the URL Standard of browsers does. The URL ends before the first other character.
  #
  # The matches are in their order in the text, and they do not overlap.
  # The time is linear in the length of the text.
  # A text with an invalid byte raises `ArgumentError`.
  class Finder
    include Enumerable

    @rules = {}.freeze

    # Returns the rules for the options. The class builds the rules of each set of options one time,
    # because the build compiles a regexp, and costs more than the scan of a short text.
    #
    # The class keeps the rules in a frozen hash, and replaces the hash to add rules, so threads
    # read it with no lock. Two threads that add rules at one time can build the same rules twice.
    def self.rules(options)
      @rules[options] || begin
        unknown_options = options.keys - DEFAULTS.keys
        raise ArgumentError, "unknown options: #{unknown_options.join(", ")}" if unknown_options.any?

        rules = BuildRules.call(**DEFAULTS, **options)
        @rules = @rules.merge(options => rules).freeze
        rules
      end
    end

    # The finder reads a frozen copy of the text, so a change of the text during the scan
    # or after it does not change what a match holds. A frozen text needs no copy.
    def initialize(text, **options)
      @text = text.frozen? ? text : text.dup.freeze
      @rules = self.class.rules(options)
    end

    # Gives each match to the block when the finder finds it. With no block, returns an enumerator.
    # Each call reads the text again: call `to_a` to keep the matches.
    def each(&block)
      return to_enum(:each) unless block

      each_match(&block)
      self
    end

    private

    # The scan gives byte indexes. In a text of ASCII characters, they are the indexes in characters.
    # In another text, counting the characters between two URLs keeps the time linear.
    def each_match
      text = @text
      ascii = text.ascii_only?
      character_index = 0
      byte_index = 0

      Scan.new(text, @rules).call do |url, url_byte_index|
        gap_size = url_byte_index - byte_index
        character_index += ascii ? gap_size : text.byteslice(byte_index, gap_size).length
        byte_index = url_byte_index

        yield Match.new(url, character_index, text)
      end
    end
  end
end
