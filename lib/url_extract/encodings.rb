# frozen_string_literal: true

require_relative "../url_extract"

class UrlExtract
  # Reads a text in an encoding other than UTF-8, such as Windows-1251, Shift_JIS, GB18030 or UTF-16LE.
  # `UrlExtract.new` loads this file when it gets such a text, so a program that reads UTF-8 only
  # does not load it. `require "url_extract/encodings"` loads it ahead.
  #
  # The extractor reads a UTF-8 copy of the text, and gives each URL in the encoding of the text.
  # Ruby converts each character of such an encoding to one UTF-8 character, so the index of a URL in the copy
  # is its index in the text, and the range of a match replaces the URL in the text.
  # The copy costs one conversion of the text for each extractor, and its memory.
  #
  # It can not read:
  # - a string of bytes (`ASCII-8BIT`) that are not ASCII: its bytes are no characters
  # - a dummy encoding, such as ISO-2022-JP or UTF-16 with a byte order mark: Ruby counts its bytes, not its
  #   characters, so an index in the copy is no index in the text
  # - an encoding that Ruby can not convert to UTF-8, such as EUC-TW, or a character with no Unicode form
  module Encodings # :nodoc: all
    class << self
      # The error names the character at fault: the first byte that is not ASCII in a string of bytes,
      # or the first character with no Unicode form. A dummy encoding, and an encoding with no converter,
      # are at fault as a whole.
      def utf8_copy(text)
        encoding = text.encoding
        if encoding == Encoding::BINARY
          Validate.unreadable("text", text, text.each_char.find_index { |byte| !byte.ascii_only? })
        end
        Validate.unreadable("text", text) if encoding.dummy?

        text.encode(Encoding::UTF_8).freeze
      rescue Encoding::ConverterNotFoundError
        Validate.unreadable("text", text)
      rescue Encoding::UndefinedConversionError => error
        Validate.unreadable("text", text, text.each_char.find_index { |character| character == error.error_char })
      end
    end

    # The methods of `UrlExtract` for a text in another encoding. A text in UTF-8 goes to the methods
    # of the class.
    module Methods
      private

      def scanned_text(text)
        Validate.utf8?(text) ? super : Encodings.utf8_copy(text)
      end

      def each_url
        return super if @scanned_text.equal?(@text)

        encoding = @text.encoding
        super { |url, index| yield url.encode(encoding), index }
      end
    end
  end

  prepend(Encodings::Methods)
end
