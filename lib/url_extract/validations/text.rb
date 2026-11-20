# frozen_string_literal: true

class UrlExtract
  module Validations # :nodoc: all
    # Checks that the extractor can read a string: the text, or a string of the options.
    # A value that is not a string raises `TypeError`, and a string that the extractor can not read
    # as UTF-8 raises `UrlExtract::EncodingError`.
    class Text # :nodoc: all
      class << self
        # The text: a string of valid bytes, in UTF-8 or in another encoding, which `Input::Encodings` reads.
        # `valid_encoding?` reads a large text fast, and Ruby keeps its result in the string.
        # The index of the invalid byte costs more, so only the error looks for it.
        def check(text)
          unless text.is_a?(String)
            Failure.fail_with("Invalid text: #{Failure.show(text)} provided", "Provide a string",
              error_class: TypeError)
          end

          unreadable("text", text, invalid_index(text)) unless text.valid_encoding?
        end

        # A string of the options: the extractor compares its bytes with the bytes of a UTF-8 text.
        def check_utf8(label, string)
          unreadable(label, string, invalid_index(string)) unless string.valid_encoding?
          unreadable(label, string) unless utf8?(string)
        end

        # The extractor reads UTF-8. A text of ASCII characters only reads the same in each encoding
        # that is compatible with ASCII, such as a string of bytes.
        def utf8?(string)
          encoding = string.encoding
          (encoding == Encoding::UTF_8) || (encoding == Encoding::US_ASCII) || string.ascii_only?
        end

        # Raises the error of each string that the extractor can not read as UTF-8, whatever the cause:
        # an invalid byte, a byte that is no character, or an encoding that the extractor can not convert.
        # The index is the index of the character at fault, when one character is at fault.
        # `Input::Encodings` raises its errors here too.
        def unreadable(label, string, index = nil)
          details = "encoding #{string.encoding}"
          details += ", index #{index}" if index
          Failure.fail_with("Invalid #{label}: can not be read as UTF-8 (#{details})", "Provide a valid UTF-8 string",
            error_class: UrlExtract::EncodingError)
        end

        private

        # The index of the first invalid character, in characters, as the index of a match.
        def invalid_index(string)
          string.each_char.find_index { |character| !character.valid_encoding? }
        end
      end
    end
  end
end
