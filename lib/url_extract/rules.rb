# frozen_string_literal: true

class UrlExtract
  # The rules of an extractor, built from its options:
  # - prefix_regexp: the regexp of each prefix, or nil when no prefix can start a URL
  # - max_bytesize: the largest size of a URL, in bytes, or infinity
  # - trim: the `Trimming::Trim` of the trim options
  # - on_encoding_error: what a text that the extractor can not read does
  #
  # The rules are frozen, as each part of them, so threads and Ractors can share them.
  Rules = Data.define(:prefix_regexp, :max_bytesize, :trim, :on_encoding_error)

  class Rules # :nodoc: all
    class << self
      # Returns the rules for the options. The rules of the default options are built one time, when the file loads.
      # Other options build their rules for each extractor: the build compiles a regexp, which costs
      # a few microseconds, about the scan of a short text. The class keeps no other rules, so it has no state
      # that threads or Ractors share.
      def from(options)
        return DEFAULT if options.empty?

        Validations::Options.check(options)
        build(**DEFAULTS, **options)
      end

      # Each option is present.
      def build(**options)
        new(
          prefix_regexp: prefix_regexp(options[:prefixes]),
          max_bytesize: options[:max_bytesize] || Float::INFINITY,
          trim: Trimming::Trim.new(**options.slice(:trim, :trim_html_entities, :trim_brackets)),
          on_encoding_error: options[:on_encoding_error]
        )
      end

      private

      # Returns the regexp of each prefix, or nil when there is no prefix.
      def prefix_regexp(prefixes)
        sources = prefixes.map { |prefix| prefix_source(prefix) }

        Regexp.new(sources.join("|"), Regexp::IGNORECASE).freeze if sources.any?
      end

      # The source of the regexp of one prefix. A prefix with `://` starts a URL at each place.
      # Another prefix, such as `www.`, starts a URL only at the start of a word, before a letter or a digit.
      def prefix_source(prefix)
        escaped_prefix = Regexp.escape(prefix)

        prefix.end_with?("://") ? escaped_prefix : "(?<![[:alnum:]])#{escaped_prefix}(?=[a-z0-9])"
      end
    end

    # The rules of the default options. Built here, as `Trimming` loads before this file.
    DEFAULT = build(**DEFAULTS)
  end
end
