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
# `UrlExtract::Finder` describes the matches and the options.
module UrlExtract
  # The list of the "Autolinks (extension)" part of the GitHub Flavored Markdown Spec, with `;`:
  # https://github.github.com/gfm/#autolinks-extension-
  TRIM = %w[? ! . , : ; * _ ~].freeze
  # RFC 9110 recommends that HTTP software supports a URL of at least 8000 bytes:
  # https://www.rfc-editor.org/rfc/rfc9110#section-4.1
  MAX_SIZE = 8000

  # The default options of a finder. `Finder` describes each option.
  DEFAULTS = {
    schemes: %w[https:// http://].freeze,
    ascii_only: false,
    max_size: MAX_SIZE,
    trim: TRIM,
    trim_html_entities: true,
    trim_brackets: :unpaired
  }.freeze

  # Returns an enumerable finder of the matches of the text. `Finder` describes the options.
  def self.matches(text, **)
    Finder.new(text, **)
  end

  # Returns the list of the URLs of the text, as strings. `Finder` describes the options.
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
require_relative "url_extract/finder"

# Builds the rules of the default options when the file loads, so no finder waits for them.
UrlExtract::Finder.rules({})
