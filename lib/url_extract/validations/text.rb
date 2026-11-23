# frozen_string_literal: true

class UrlExtract
  module Validations # :nodoc: all
    # Checks the text of an extractor. A text that is not a string raises `TypeError`, and a text that
    # the extractor can not read as UTF-8 raises `UrlExtract::EncodingError`, which `on_encoding_error` handles.
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

          fail_unreadable(text, invalid_index(text)) unless text.valid_encoding?
        end

        # The extractor reads UTF-8. A text of ASCII characters only reads the same in each encoding
        # that is compatible with ASCII, such as a string of bytes.
        def utf8?(text)
          encoding = text.encoding
          (encoding == Encoding::UTF_8) || (encoding == Encoding::US_ASCII) || text.ascii_only?
        end

        # Raises the error of a text that the extractor can not read as UTF-8, whatever the cause:
        # an invalid byte, a byte that is no character, or an encoding that the extractor can not convert.
        # The index is the index of the character at fault, when one character is at fault.
        # `Input::Encodings` raises its errors here too.
        def fail_unreadable(text, index = nil)
          details = "encoding #{text.encoding}"
          details += ", index #{index}" if index
          Failure.fail_with("Invalid text: can not be read as UTF-8 (#{details})", "Provide a valid UTF-8 string",
            error_class: UrlExtract::EncodingError)
        end

        private

        # The index of the first invalid character, in characters, as the index of a match.
        def invalid_index(text)
          text.each_char.find_index { |character| !character.valid_encoding? }
        end
      end
    end
  end
end
