# frozen_string_literal: true

module UrlExtract
  # Checks the text and the options of `UrlExtract::Finder.new`. For a value that the finder can not take,
  # it raises an error of two lines: what is wrong, and a short hint of what to provide.
  #
  #   UrlExtract.urls(text, trim: ".")
  #   # ArgumentError: Invalid value for trim: "." provided
  #   # [hint] Provide array of strings like ["?", "!", ".", ",", ":", ";", "*", "_", "~"]
  #
  # A text that is not a string raises `TypeError`. Each other wrong value raises `ArgumentError`.
  class Validate # :nodoc: all
    TRIM_BRACKETS = %i[unpaired none].freeze
    # The longest part of a wrong value that an error shows. The value can be a long text, given by mistake.
    MAX_SHOWN_SIZE = 60

    class << self
      # `valid_encoding?` and `ascii_only?` read a large text fast, and Ruby keeps their result in the string.
      # The index of the invalid byte costs more, so only the error looks for it.
      def text(text)
        fail_with("Invalid text: #{show(text)} provided", "Provide a string", error_class: TypeError) unless text.is_a?(String)

        unless text.valid_encoding?
          fail_with("Invalid text: invalid byte for #{text.encoding} at index #{invalid_index(text)}",
            "Replace invalid bytes with text.scrub")
        end
        return if utf8?(text)

        hint = if text.encoding == Encoding::BINARY
          "Mark it as UTF-8: text.dup.force_encoding(Encoding::UTF_8)"
        else
          "Encode it to UTF-8: text.encode(Encoding::UTF_8)"
        end
        fail_with("Invalid text: encoding #{text.encoding} is not supported", hint)
      end

      # The finder reads UTF-8. A text of ASCII characters only reads the same in each encoding
      # that is compatible with ASCII, such as a string of bytes.
      def utf8?(string)
        encoding = string.encoding
        (encoding == Encoding::UTF_8) || (encoding == Encoding::US_ASCII) || string.ascii_only?
      end

      def options(options)
        check_names(options.keys)

        # Each option has a private method of its name, and `check_names` lets only these names through.
        options.each { |name, value| send(name, value) }
      end

      private

      def check_names(names)
        unknown_names = names - DEFAULTS.keys
        return if unknown_names.empty?

        label = unknown_names.one? ? "option" : "options"
        fail_with("Unknown #{label} #{unknown_names.map { |name| show(name) }.join(", ")}",
          "Allowed options: #{DEFAULTS.keys.map(&:inspect).join(", ")}")
      end

      def schemes(schemes)
        check_array(:schemes, schemes)

        schemes.each do |scheme|
          check_string("scheme", scheme, %("https://" or "www."))
          if scheme.match?(/[[:space:]]/)
            fail_with("Invalid scheme: #{show(scheme)} provided", "Remove the spaces")
          end
          # A start such as `https` holds no `:` and no `.`, so it starts a URL only in a word such as `httpsx`.
          if scheme.match?(/\A[[:alnum:]+-]+\z/)
            fail_with("Invalid scheme: #{show(scheme)} provided", %(End it with "://" or ".", like "https://" or "www."))
          end
        end
      end

      def max_size(max_size)
        return if max_size.nil? || (max_size.is_a?(Integer) && max_size.positive?)

        fail_with("Invalid value for max_size: #{show(max_size)} provided",
          "Provide a positive integer like #{DEFAULTS[:max_size]}, or nil for no limit")
      end

      def trim(trim)
        check_array(:trim, trim)
        trim.each { |string| check_string("trim string", string, '"."') }
      end

      def trim_html_entities(value)
        return if (value == true) || (value == false)

        fail_with("Invalid value for trim_html_entities: #{show(value)} provided", "Provide true or false")
      end

      def trim_brackets(value)
        return if TRIM_BRACKETS.include?(value)

        fail_with("Invalid value for trim_brackets: #{show(value)} provided", "Provide :unpaired or :none")
      end

      def check_array(name, value)
        return if value.is_a?(Array)

        fail_with("Invalid value for #{name}: #{show(value)} provided",
          "Provide array of strings like #{DEFAULTS[name].inspect}")
      end

      # The finder compares the bytes of the string with the bytes of a UTF-8 text.
      def check_string(label, string, example)
        unless string.is_a?(String) && !string.empty?
          fail_with("Invalid #{label}: #{show(string)} provided", "Provide a non-empty string like #{example}")
        end
        return if string.valid_encoding? && utf8?(string)

        fail_with("Invalid #{label}: #{show(string)} provided", "Provide a valid UTF-8 string")
      end

      def fail_with(message, hint, error_class: ArgumentError)
        raise error_class, "#{message}\n[hint] #{hint}"
      end

      # The index of the first invalid character, in characters, as the index of a match.
      def invalid_index(text)
        text.each_char.find_index { |character| !character.valid_encoding? }
      end

      # Shows a value in an error: the result of `inspect`, cut to `MAX_SHOWN_SIZE` characters.
      def show(value)
        shown = value.inspect
        (shown.length > MAX_SHOWN_SIZE) ? "#{shown[0, MAX_SHOWN_SIZE]}..." : shown
      end
    end
  end
end
