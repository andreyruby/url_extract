# frozen_string_literal: true

class UrlExtract
  module Validations # :nodoc: all
    # Checks the options of `UrlExtract.new`: each name, and the type and the value of each option.
    # A wrong option raises `ArgumentError`, with a hint of what to provide:
    #
    #   UrlExtract.scan(text, trim: ".")
    #   # ArgumentError: Invalid value for trim: "." provided
    #   # [hint] Provide array of strings like ["?", "!", ".", ",", ":", ";", "*", "_", "~"]
    class Options # :nodoc: all
      ON_ENCODING_ERROR = %i[warn skip raise].freeze
      # The private method that checks each option: `check_` and the name of the option.
      CHECK_METHODS = DEFAULTS.keys.to_h { |name| [name, :"check_#{name}"] }.freeze

      class << self
        def check(options)
          check_names(options.keys)

          # `check_names` lets only the names of `CHECK_METHODS` through.
          options.each { |name, value| send(CHECK_METHODS[name], value) }
        end

        private

        def check_names(names)
          unknown_names = names - DEFAULTS.keys
          return if unknown_names.empty?

          label = unknown_names.one? ? "option" : "options"
          Failure.fail_with("Unknown #{label} #{unknown_names.map { |name| Failure.show(name) }.join(", ")}",
            "Allowed options: #{DEFAULTS.keys.map(&:inspect).join(", ")}")
        end

        def check_prefixes(prefixes)
          check_array(:prefixes, prefixes)

          prefixes.each do |prefix|
            check_string("prefix", prefix, %("https://" or "www."))
            if prefix.match?(/[[:space:]]/)
              Failure.fail_with("Invalid prefix: #{Failure.show(prefix)} provided", "Remove the spaces")
            end
            # A start such as `https` holds no `:` and no `.`, so it starts a URL only in a word such as `httpsx`.
            if prefix.match?(/\A[[:alnum:]+-]+\z/)
              Failure.fail_with("Invalid prefix: #{Failure.show(prefix)} provided",
                %(End it with "://" or ".", like "https://" or "www."))
            end
          end
        end

        def check_max_bytesize(max_bytesize)
          return if max_bytesize.nil? || (max_bytesize.is_a?(Integer) && max_bytesize.positive?)

          Failure.fail_with("Invalid value for max_bytesize: #{Failure.show(max_bytesize)} provided",
            "Provide a positive integer like #{DEFAULTS[:max_bytesize]}, or nil for no limit")
        end

        def check_trim(trim)
          check_array(:trim, trim)
          trim.each { |string| check_string("trim string", string, '"."') }
        end

        def check_trim_html_entities(value) = check_boolean(:trim_html_entities, value)

        def check_trim_brackets(value) = check_boolean(:trim_brackets, value)

        def check_on_encoding_error(value)
          return if ON_ENCODING_ERROR.include?(value)

          Failure.fail_with("Invalid value for on_encoding_error: #{Failure.show(value)} provided",
            "Provide :warn, :skip or :raise")
        end

        def check_boolean(name, value)
          return if (value == true) || (value == false)

          Failure.fail_with("Invalid value for #{name}: #{Failure.show(value)} provided", "Provide true or false")
        end

        def check_array(name, value)
          return if value.is_a?(Array)

          Failure.fail_with("Invalid value for #{name}: #{Failure.show(value)} provided",
            "Provide array of strings like #{DEFAULTS[name].inspect}")
        end

        def check_string(label, string, example)
          unless string.is_a?(String) && !string.empty?
            Failure.fail_with("Invalid #{label}: #{Failure.show(string)} provided",
              "Provide a non-empty string like #{example}")
          end
          return if utf8?(string)

          Failure.fail_with("Invalid #{label}: #{Failure.show(string)} provided", "Provide a UTF-8 string")
        end

        # The extractor compares the bytes of the string with the bytes of a UTF-8 text: a string in another
        # encoding, such as `"»"` in Windows-1251, would cut a byte of a character from the end of a URL.
        # A string of ASCII characters only reads the same in each encoding that is compatible with ASCII.
        def utf8?(string)
          string.valid_encoding? && ((string.encoding == Encoding::UTF_8) || string.ascii_only?)
        end
      end
    end
  end
end
