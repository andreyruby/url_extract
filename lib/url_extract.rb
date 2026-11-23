# frozen_string_literal: true

require "strscan"

require_relative "url_extract/version"

# Finds and extracts each URL in a text.
#
#   UrlExtract.scan("See https://a.com/x. And https://a.com/x").map(&:url)
#   # => ["https://a.com/x", "https://a.com/x"]
#
# The URLs are raw: each URL as the text writes it, at each place, so a URL can come more than one time.
#
#   match = UrlExtract.scan("See https://a.com/x.").first
#   match.url   # => "https://a.com/x"
#   match.range # => 4...19
#
# `UrlExtract.scan(text)`, its short form `UrlExtract.(text)`, and `UrlExtract.new(text)` return an extractor:
# a `UrlExtract`, which is enumerable:
#
#   extractor = UrlExtract.new(text, prefixes: %w[https:// http:// www.])
#
#   extractor.each { |match| puts match.url } # each match, when the extractor finds it
#   extractor.to_a                            # the list of the matches
#   extractor.first(3)                        # the first 3 matches: it reads the text up to the third
#   extractor.map(&:url)
#
# The class builds the rules of the default options one time, so a new extractor for each text costs little.
# An extractor with other options builds its rules, which costs a few microseconds.
# The class and each extractor are thread-safe, and each Ractor can use the class: the rules are frozen,
# and each call of `each` reads the text with a scanner of its own.
#
# A match has:
# - url: the URL as the text writes it. In HTML it can hold a character reference, such as `&amp;`.
# - text: a frozen copy of the text, as it was when the extractor read it.
# - range: the place of the URL in the text, in characters. It replaces the URL:
#
#     text[match.range] = '<FILTERED>'
#
#   To replace more than one URL, go from the last match to the first, as `reverse_each` does.
#   A replacement moves the URLs after it.
# - to_s: the URL, so `puts match` gives it. `inspect` shows the URL and the range, and not the text.
#
# The text is a plain text: the extractor reads no tag. In HTML it finds a URL that starts with a scheme,
# also in an attribute, and it does not find a relative URL, such as `href="/path"`.
#
# The options:
# - prefixes: what starts a URL. A prefix with `://` starts a URL at each place.
#   Another start, such as `www.`, starts a URL only at the start of a word, before a letter or a digit.
# - max_bytesize: the largest size of a URL, in bytes. The extractor gives no match for a longer URL,
#   and no match for a part of it. `nil` sets no limit.
# - trim: the strings to remove from the end of a URL, as `See https://a.com/x.` needs. `[]` removes nothing.
# - trim_html_entities: `true` removes an HTML entity from the end of a URL, such as `&quot;`, `&#39;`
#   or `&#x27;`. `false` keeps it. An entity is one unit: the `;` of the `trim` list does not cut its end.
# - trim_brackets: `true` removes from the end of a URL a closing bracket that the URL
#   does not open, and an opening bracket that the URL does not close. `false` removes no bracket.
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

  # The error of a text that the extractor can not read as UTF-8: an invalid byte, a byte that is no character,
  # or an encoding that the extractor can not convert.
  #
  # It raises only with `on_encoding_error: :raise`. With the default, `:warn`, such a text gives no match
  # and warns, and with `:skip` it gives no match and says nothing.
  #
  # It is an `ArgumentError`, as Ruby raises for an invalid byte. It is not Ruby's `::EncodingError`.
  class EncodingError < ArgumentError; end

  # The default options of an extractor. `UrlExtract` describes each option.
  DEFAULTS = {
    prefixes: %w[https:// http://].freeze,
    # RFC 9110 recommends that HTTP software supports a URL of at least 8000 bytes:
    # https://www.rfc-editor.org/rfc/rfc9110#section-4.1
    max_bytesize: 8000,
    # The list of the "Autolinks (extension)" part of the GitHub Flavored Markdown Spec, with `;`:
    # https://github.github.com/gfm/#autolinks-extension-
    trim: %w[? ! . , : ; * _ ~].freeze,
    trim_html_entities: true,
    trim_brackets: true,
    on_encoding_error: :warn
  }.freeze

  # The longest part of the text that `inspect` shows.
  INSPECTED_TEXT_SIZE = 60
  private_constant :INSPECTED_TEXT_SIZE

  # Returns an extractor of the matches of the text: a `UrlExtract`. `UrlExtract` describes the options.
  def self.scan(text, **)
    new(text, **)
  end

  class << self
    # The same as `scan`, so `UrlExtract.(text)` works too.
    alias_method :call, :scan
  end

  # A wrong option raises `ArgumentError`, and a text that is not a string raises `TypeError`.
  # A text that the extractor can not read as UTF-8 gives no match: `on_encoding_error` says whether it also
  # warns (`:warn`), says nothing (`:skip`), or raises (`:raise`).
  def initialize(text, **options)
    @reader = Input::Reader.new(text, Rules.from(options))
  end

  # Gives each match to the block when the extractor finds it. With no block, returns an enumerator.
  # Each call reads the text again: call `to_a` to keep the matches.
  def each
    return to_enum(:each) unless block_given?

    text = @reader.text
    @reader.each_url { |url, index| yield Match.new(url, index, text) }
    self
  end

  # Shows the start of the text, and not the rules of the options: `#<UrlExtract text="See https://a.com/x.">`.
  # A text that the extractor can not read shows as nil.
  def inspect
    shown = @reader.text.inspect
    shown = "#{shown[0, INSPECTED_TEXT_SIZE]}..." if shown.length > INSPECTED_TEXT_SIZE
    "#<#{self.class} text=#{shown}>"
  end
end

require_relative "url_extract/match"
require_relative "url_extract/scanner"
require_relative "url_extract/input/encoding_error_policy"
require_relative "url_extract/input/reader"
require_relative "url_extract/trimming/ending_entity_size"
require_relative "url_extract/trimming/ending_string_size"
require_relative "url_extract/trimming/index_after_last_paired_bracket"
require_relative "url_extract/trimming/trim"
require_relative "url_extract/validations/failure"
require_relative "url_extract/validations/options"
require_relative "url_extract/validations/text"

# Last: it builds the rules of the default options with the classes above.
require_relative "url_extract/rules"
