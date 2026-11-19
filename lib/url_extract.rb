# frozen_string_literal: true

require "strscan"

require_relative "url_extract/version"

# Finds and extracts each URL in a text.
#
#   UrlExtract.matches("See https://a.com/x. And https://a.com/x").map(&:url)
#   # => ["https://a.com/x", "https://a.com/x"]
#
# The URLs are raw: each URL as the text writes it, at each place, so a URL can come more than one time.
#
#   match = UrlExtract.matches("See https://a.com/x.").first
#   match.url   # => "https://a.com/x"
#   match.index # => 4
#   match.range # => 4...19
#
# `UrlExtract.matches(text)` and `UrlExtract.new(text)` return an extractor: a `UrlExtract`, which is enumerable:
#
#   extractor = UrlExtract.new(text, schemes: %w[https:// http:// www.])
#
#   extractor.each { |match| puts match.url } # each match, when the extractor finds it
#   extractor.to_a                            # the list of the matches
#   extractor.first(3)                        # the first 3 matches: it reads the text up to the third
#   extractor.map(&:url)
#
# The class builds the rules of each set of options one time, so a new extractor for each text costs little.
#
# A match has:
# - url: the URL as the text writes it. In HTML it can hold a character reference, such as `&amp;`.
# - index: the index of the URL in the text, in characters.
# - text: a frozen copy of the text, as it was when the extractor read it.
# - range: the place of the URL in the text. It replaces the URL:
#
#     text[match.range] = '<FILTERED>'
#
#   To replace more than one URL, go from the last match to the first, as `reverse_each` does.
#   A replacement moves the URLs after it.
#
# The text is a plain text: the extractor reads no tag. In HTML it finds a URL that starts with a scheme,
# also in an attribute, and it does not find a relative URL, such as `href="/path"`.
#
# The options:
# - schemes: what starts a URL. A scheme with `://` starts a URL at each place.
#   Another start, such as `www.`, starts a URL only at the start of a word, before a letter or a digit.
# - max_size: the largest size of a URL, in bytes. The extractor gives no match for a longer URL,
#   and no match for a part of it. `nil` sets no limit.
# - trim: the strings to remove from the end of a URL, as `See https://a.com/x.` needs. `[]` removes nothing.
# - trim_html_entities: `true` removes an HTML entity from the end of a URL, such as `&quot;`, `&#39;`
#   or `&#x27;`. `false` keeps it. An entity is one unit: the `;` of the `trim` list does not cut its end.
# - trim_brackets: `:unpaired` removes from the end of a URL a closing bracket that the URL
#   does not open, and an opening bracket that the URL does not close. `:none` removes no bracket.
# - on_encoding_error: what a text that the extractor can not read as UTF-8 does. It gives no match,
#   and `:warn` warns at the line of the caller, `:skip` says nothing, and `:raise` raises the error instead.
#
# A URL holds the characters of RFC 3986, and each character that is not ASCII and not a space,
# as the URL Standard of browsers does. The URL ends before the first other character.
#
# The matches are in their order in the text, and they do not overlap.
# The time is linear in the length of the text.
# The extractor reads UTF-8. A text in another encoding, such as Windows-1251 or Shift_JIS, first loads
# `url_extract/encodings`, which reads a UTF-8 copy of the text. A text of ASCII characters only needs no copy.
#
# A wrong option raises `ArgumentError`, and a text that is not a string raises `TypeError`: they are bugs
# of the calling code. With `on_encoding_error: :raise`, a text with an invalid byte, or in an encoding
# that the extractor can not read, raises `UrlExtract::EncodingError`, an `ArgumentError`.
# The second line of each message is a hint of what to provide.
class UrlExtract
  include Enumerable

  # The list of the "Autolinks (extension)" part of the GitHub Flavored Markdown Spec, with `;`:
  # https://github.github.com/gfm/#autolinks-extension-
  TRIM = %w[? ! . , : ; * _ ~].freeze
  # RFC 9110 recommends that HTTP software supports a URL of at least 8000 bytes:
  # https://www.rfc-editor.org/rfc/rfc9110#section-4.1
  MAX_SIZE = 8000

  # The error of a text, or of a string of the options, that the extractor can not read as UTF-8:
  # an invalid byte, a byte that is no character, or an encoding that the extractor can not convert.
  # It is an `ArgumentError`, as Ruby raises for an invalid byte. It is not Ruby's `::EncodingError`.
  class EncodingError < ArgumentError; end

  # The default options of an extractor. `UrlExtract` describes each option.
  DEFAULTS = {
    schemes: %w[https:// http://].freeze,
    max_size: MAX_SIZE,
    trim: TRIM,
    trim_html_entities: true,
    trim_brackets: :unpaired,
    on_encoding_error: :warn
  }.freeze

  # The start of the path of each file of the gem. A warning names the first line outside them: the caller's.
  SOURCE_PATH = File.join(__dir__, "url_extract")
  private_constant :SOURCE_PATH

  # Returns an extractor of the matches of the text: a `UrlExtract`. `UrlExtract` describes the options.
  def self.matches(text, **)
    new(text, **)
  end

  # A wrong option raises `ArgumentError`, and a text that is not a string raises `TypeError`.
  # A text that the extractor can not read as UTF-8 gives no match: `on_encoding_error` says whether it also
  # warns (`:warn`), says nothing (`:skip`), or raises (`:raise`).
  def initialize(text, **options)
    @rules = BuildRules.cached(options)
    @text, @scanned_text = read(text)
  end

  # Gives each match to the block when the extractor finds it. With no block, returns an enumerator.
  # Each call reads the text again: call `to_a` to keep the matches.
  def each
    return to_enum(:each) unless block_given?

    text = @text
    each_url { |url, index| yield Match.new(url, index, text) }
    self
  end

  private

  # Returns the text and the text that the scan reads, or nil and nil for a text that the extractor can not read.
  #
  # The extractor reads a frozen copy of the text, so a change of the text during the scan
  # or after it does not change what a match holds. A frozen text needs no copy.
  # `url_extract/encodings` changes `scanned_text` and `each_url` of the class, for each extractor after it.
  def read(text)
    Validate.text(text)
    text = text.frozen? ? text : text.dup.freeze
    require_relative "url_extract/encodings" unless Validate.utf8?(text)
    [text, scanned_text(text)]
  rescue EncodingError => error
    skip(error)
  end

  def skip(error)
    case @rules.on_encoding_error
    when :raise then raise error
    when :warn
      # The caller's line, in the form of Ruby's warnings. `uplevel:` counts no C frame, such as `Class#new`,
      # so it can not take an index of `caller_locations`.
      locations = caller_locations
      caller = locations.find { |location| !location.path.start_with?(SOURCE_PATH) } || locations.last
      warn("#{caller.path}:#{caller.lineno}: warning: url_extract: #{error.message}")
    end

    [nil, nil]
  end

  # The text that the scan reads: the text itself, in UTF-8 or of ASCII characters only.
  def scanned_text(text)
    text
  end

  # Gives each URL of the scanned text, and its index in characters.
  # The scan gives byte indexes. In a text of ASCII characters, they are the indexes in characters.
  # In another text, counting the characters between two URLs keeps the time linear.
  def each_url
    text = @scanned_text
    return unless text

    ascii = text.ascii_only?
    character_index = 0
    byte_index = 0

    Scan.new(text, @rules).call do |url, url_byte_index|
      gap_size = url_byte_index - byte_index
      character_index += ascii ? gap_size : text.byteslice(byte_index, gap_size).length
      byte_index = url_byte_index

      yield url, character_index
    end
  end
end

require_relative "url_extract/build_rules"
require_relative "url_extract/entity_end_size"
require_relative "url_extract/long_string_end_size"
require_relative "url_extract/match"
require_relative "url_extract/paired_bracket_end"
require_relative "url_extract/scan"
require_relative "url_extract/trim"
require_relative "url_extract/validate"

# Builds the rules of the default options when the file loads, so no extractor waits for them.
UrlExtract::BuildRules.cached({})
