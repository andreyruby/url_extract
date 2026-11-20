# frozen_string_literal: true

class UrlExtract
  # Checks the text and the options of `UrlExtract.new`. For a value that the extractor can not take,
  # it raises an error of two lines: what is wrong, and a short hint of what to provide.
  #
  #   UrlExtract.scan(text, trim: ".")
  #   # ArgumentError: Invalid value for trim: "." provided
  #   # [hint] Provide array of strings like ["?", "!", ".", ",", ":", ";", "*", "_", "~"]
  #
  # A text that is not a string raises `TypeError`. Each other wrong value raises `ArgumentError`.
  class Validate # :nodoc: all
    TRIM_BRACKETS = %i[unpaired none].freeze
    ON_ENCODING_ERROR = %i[warn skip raise].freeze
    # The longest part of a wrong value that an error shows. The value can be a long text, given by mistake.
    MAX_SHOWN_SIZE = 60

    class << self
      # `valid_encoding?` and `ascii_only?` read a large text fast, and Ruby keeps their result in the string.
      # The index of the invalid byte costs more, so only the error looks for it.
      def text(text)
        fail_with("Invalid text: #{show(text)} provided", "Provide a string", error_class: TypeError) unless text.is_a?(String)

        unreadable("text", text, invalid_index(text)) unless text.valid_encoding?
      end

      # The extractor reads UTF-8. A text of ASCII characters only reads the same in each encoding
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

      # Raises the error of each string that the extractor can not read as UTF-8, whatever the cause:
      # an invalid byte, a byte that is no character, or an encoding that the extractor can not convert.
      # The index is the index of the character at fault, when one character is at fault.
      # `url_extract/encodings` raises its errors here too.
      def unreadable(label, string, index = nil)
        details = "encoding #{string.encoding}"
        details += ", index #{index}" if index
        fail_with("Invalid #{label}: can not be read as UTF-8 (#{details})", "Provide a valid UTF-8 string",
          error_class: UrlExtract::EncodingError)
      end

      private

      def fail_with(message, hint, error_class: ArgumentError)
        raise error_class, "#{message}\n[hint] #{hint}"
      end

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

      def on_encoding_error(value)
        return if ON_ENCODING_ERROR.include?(value)

        fail_with("Invalid value for on_encoding_error: #{show(value)} provided", "Provide :warn, :skip or :raise")
      end

      def check_array(name, value)
        return if value.is_a?(Array)

        fail_with("Invalid value for #{name}: #{show(value)} provided",
          "Provide array of strings like #{DEFAULTS[name].inspect}")
      end

      # The extractor compares the bytes of the string with the bytes of a UTF-8 text.
      def check_string(label, string, example)
        unless string.is_a?(String) && !string.empty?
          fail_with("Invalid #{label}: #{show(string)} provided", "Provide a non-empty string like #{example}")
        end
        unreadable(label, string, invalid_index(string)) unless string.valid_encoding?
        unreadable(label, string) unless utf8?(string)
      end

      # The index of the first invalid character, in characters, as the index of a match.
      # Only an error looks for it.
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
