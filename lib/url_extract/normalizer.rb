# frozen_string_literal: true

require "nokogiri"

module UrlExtract
  # Returns the URL that a browser reads from a raw URL. A raw URL is a URL as HTML or a text writes it,
  # such as a URL that `UrlExtract` finds.
  #
  #   UrlExtract::Normalizer.call('https:\\a.com\x?&#97;f=1&amp;b=2') # => "https://a.com/x?af=1&b=2"
  #
  # A raw URL can hold HTML character references (`&#97;f=`), control characters and backslashes.
  # Nokogiri decodes the character references as a browser does in an attribute value:
  # it does not decode `&copy=2`, which is a parameter.
  # The percent-encoding stays, because a server can depend on it.
  #
  # It returns the raw URL itself when the raw URL holds none of these, which is the usual case.
  #
  # It needs the `nokogiri` gem, which is no dependency of this gem. Load it when the app needs it:
  #
  #   require "url_extract/normalizer"
  class Normalizer
    # The control characters, as the argument of `String#delete`.
    CONTROL_CHARACTERS = "\x00-\x1F"
    # A raw URL with none of these characters is normalized.
    NOT_NORMALIZED = /[&\\\x00-\x20]/
    # The character reference of `&`.
    ESCAPED_AMPERSAND = "&amp;"
    # An `&` that can start another character reference than `&amp;`.
    # An `&` before a name and `=` starts a parameter: a browser decodes no reference there.
    OTHER_REFERENCE = /&(?!amp;|[a-z0-9]+=)/i

    class << self
      # Returns the URL that a browser reads from the raw URL.
      def call(raw_url)
        return raw_url unless raw_url.match?(NOT_NORMALIZED)

        decoded_url = raw_url.include?("&") ? decode(raw_url) : raw_url

        clean(decoded_url)
      end

      private

      # `&amp;` and the `&` of a parameter are the usual ones in a URL, and need no parser.
      def decode(raw_url)
        raw_url.match?(OTHER_REFERENCE) ? decode_references(raw_url) : raw_url.gsub(ESCAPED_AMPERSAND, "&")
      end

      def decode_references(raw_url)
        quoted_url = raw_url.gsub('"', "&quot;")
        anchor = Nokogiri::HTML5.fragment(%(<a href="#{quoted_url}">)).at("a")

        anchor["href"]
      end

      # Deletes each control character, and the spaces around the URL. A browser removes each tab and newline,
      # and the control characters around the URL.
      # Reads a `\` before the query and the fragment as a `/`, as a browser does.
      # No URL parser does this work: `Addressable` and `URI` keep a `\`, or refuse the URL.
      def clean(decoded_url)
        trimmed_url = decoded_url.delete(CONTROL_CHARACTERS).strip
        location, separator, rest = trimmed_url.partition(/[?#]/)
        slashed_location = location.tr("\\", "/")

        "#{slashed_location}#{separator}#{rest}"
      end
    end
  end
end
