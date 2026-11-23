# frozen_string_literal: true

class UrlExtract
  module Trimming # :nodoc: all
    # Returns the count of the bytes of the string that ends a URL, for the strings of the `trim` list
    # that have more than one byte, such as `...` or `»`. Returns 0 when no string ends the URL.
    # When more than one string ends the URL, it takes the longest.
    #
    # It compares the bytes of each string with the last bytes of the URL, and makes no object.
    class EndingStringSize # :nodoc: all
      def initialize(strings)
        longest_first_strings = strings.sort_by { |string| -string.bytesize }
        @byte_sequences = longest_first_strings.map { |string| string.bytes.freeze }.freeze
        freeze
      end

      # The URL is the bytes of the text from `start` to `finish`.
      # The loops are `while` loops: a `return` out of a block makes an object.
      def call(text, start, finish)
        byte_sequences = @byte_sequences
        count = byte_sequences.size
        index = 0

        while index < count
          bytes = byte_sequences[index]
          return bytes.size if ends_with?(text, start, finish, bytes)

          index += 1
        end

        0
      end

      private

      def ends_with?(text, start, finish, bytes)
        size = bytes.size
        string_start = finish - size
        return false if string_start < start

        index = 0
        index += 1 while (index < size) && (text.getbyte(string_start + index) == bytes[index])

        index == size
      end
    end
  end
end
