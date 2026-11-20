# frozen_string_literal: true

class UrlExtract
  # The rules of an extractor, built from its options:
  # - start: the regexp of each prefix, or nil when nothing can start a URL
  # - max_bytesize: the largest size of a URL, in bytes, or infinity
  # - trim: the `Trimming::Trim` of the trim options
  # - on_encoding_error: what a text that the extractor can not read does
  Rules = Data.define(:start, :max_bytesize, :trim, :on_encoding_error)

  class Rules # :nodoc: all
    @cache = {}.freeze

    class << self
      # Returns the rules for the options. It builds the rules of each set of options one time,
      # because the build compiles a regexp, and costs more than the scan of a short text.
      #
      # It keeps the rules in a frozen hash, and replaces the hash to add rules, so threads
      # read it with no lock. Two threads that add rules at one time can build the same rules twice.
      def cached(options)
        @cache[options] || begin
          Validations::Options.check(options)
          rules = build(**DEFAULTS, **options)
          @cache = @cache.merge(options => rules).freeze
          rules
        end
      end

      # Each option is present.
      def build(**options)
        new(
          start: start(options[:prefixes]),
          max_bytesize: options[:max_bytesize] || Float::INFINITY,
          trim: Trimming::Trim.new(**options.slice(:trim, :trim_html_entities, :trim_brackets)),
          on_encoding_error: options[:on_encoding_error]
        )
      end

      private

      # Returns the regexp of each start of a URL, or nil when nothing can start.
      def start(prefixes)
        starts = prefixes.map { |prefix| prefix_start(prefix) }
        source = starts.join("|")

        Regexp.new(source, Regexp::IGNORECASE) if starts.any?
      end

      # A prefix with `://` starts a URL at each place. Another start, such as `www.`, starts a URL
      # only at the start of a word, before a letter or a digit.
      def prefix_start(prefix)
        escaped_prefix = Regexp.escape(prefix)

        prefix.end_with?("://") ? escaped_prefix : "(?<![[:alnum:]])#{escaped_prefix}(?=[a-z0-9])"
      end
    end
  end
end
