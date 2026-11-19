# frozen_string_literal: true

module UrlExtract
  # Builds the rules of a finder from the options of `UrlExtract::Finder.new`.
  class BuildRules # :nodoc: all
    Rules = Data.define(:start, :max_size, :trim)

    class << self
      # Each option is present.
      def call(**options)
        start = start(options[:schemes])
        max_size = options[:max_size] || Float::INFINITY
        trim = UrlExtract::Trim.new(**options.slice(:trim, :trim_html_entities, :trim_brackets))

        Rules.new(start:, max_size:, trim:)
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
