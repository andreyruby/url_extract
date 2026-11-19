# frozen_string_literal: true

require "strscan"

require_relative "url_extract/version"

# Finds and extracts each URL in a text.
#
#   UrlExtract.urls("See https://a.com/x.") # => ["https://a.com/x"]
#
#   match = UrlExtract.matches("See https://a.com/x.").first
#   match.url   # => "https://a.com/x"
#   match.index # => 4
#   match.range # => 4...19
#
# `UrlExtract::Extractor` describes the matches and the options.
module UrlExtract
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

  # The default options of an extractor. `Extractor` describes each option.
  DEFAULTS = {
    schemes: %w[https:// http://].freeze,
    max_size: MAX_SIZE,
    trim: TRIM,
    trim_html_entities: true,
    trim_brackets: :unpaired
  }.freeze

  # Returns an enumerable extractor of the matches of the text. `Extractor` describes the options.
  def self.matches(text, **)
    Extractor.new(text, **)
  end

  # Returns the list of the URLs of the text, as strings. `Extractor` describes the options.
  def self.urls(text, **)
    matches(text, **).map(&:url)
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
require_relative "url_extract/extractor"

# Builds the rules of the default options when the file loads, so no extractor waits for them.
UrlExtract::Extractor.rules({})
