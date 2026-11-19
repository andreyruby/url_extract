# frozen_string_literal: true

module UrlExtract
  # Builds the rules of a finder from the options of `UrlExtract::Finder.new`.
  class BuildRules # :nodoc: all
    Rules = Data.define(:start, :characters, :max_size, :trim)

    # The characters that RFC 3986 allows in a URL, as the content of a regexp character class:
    # - unreserved: letters, digits and `-._~` (https://www.rfc-editor.org/rfc/rfc3986#section-2.3)
    # - reserved: `:/?#[]@` and `!$&'()*+,;=` (https://www.rfc-editor.org/rfc/rfc3986#section-2.2)
    # - `%`, which starts a percent-encoded byte (https://www.rfc-editor.org/rfc/rfc3986#section-2.1)
    # The whole grammar is in https://www.rfc-editor.org/rfc/rfc3986#appendix-A
    RFC3986_CHARACTERS = "A-Za-z0-9\\-._~:/?#\\[\\]@!$&'()*+,;=%"

    # The characters of a URL, by the `ascii_only` option.
    # Without `ascii_only`, a URL also holds each character that is not ASCII and not a space.
    # The URL Standard of browsers allows these: https://url.spec.whatwg.org/#url-code-points
    CHARACTERS = {
      true => /[#{RFC3986_CHARACTERS}]*/,
      false => /(?:[#{RFC3986_CHARACTERS}]|[[^\x00-\x7F]&&[^[:space:]]])*/
    }.freeze

    class << self
      # Each option is present.
      def call(**options)
        start = start(options[:schemes])
        characters = CHARACTERS.fetch(options[:ascii_only] ? true : false)
        max_size = options[:max_size] || Float::INFINITY
        trim = UrlExtract::Trim.new(**options.slice(:trim, :trim_html_entities, :trim_brackets))

        Rules.new(start:, characters:, max_size:, trim:)
      end

      private

      # Returns the regexp of each start of a URL, or nil when nothing can start.
      def start(schemes)
        starts = schemes.map { |scheme| scheme_start(scheme) }
        source = starts.join("|")

        Regexp.new(source, Regexp::IGNORECASE) if starts.any?
      end

      # A scheme with `://` starts a URL at each place. Another start, such as `www.`, starts a URL
      # only at the start of a word, before a letter or a digit.
      def scheme_start(scheme)
        escaped_scheme = Regexp.escape(scheme)

        scheme.end_with?("://") ? escaped_scheme : "(?<![[:alnum:]])#{escaped_scheme}(?=[a-z0-9])"
      end
    end
  end
end
