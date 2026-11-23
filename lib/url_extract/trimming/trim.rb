# frozen_string_literal: true

class UrlExtract
  module Trimming # :nodoc: all
    # Finds how much of a URL in a text stays, when the end of the URL belongs to the text around it. It removes:
    # - each string of the list, such as the dot of `See https://example.com/x.`
    # - with `trim_html_entities`, an HTML entity, such as the `&quot;` of `https://example.com/x&quot;`
    # - with `trim_brackets`, a bracket with no partner, as `IndexAfterLastPairedBracket` says:
    #   the `)` of `(https://example.com/x)` and the `(` of `https://example.com/x( see)`. A bracket with a partner stays,
    #   as in `https://example.com/x_(y)`.
    #
    # It repeats these until the last character of the URL stays.
    # An HTML entity is one unit: without `trim_html_entities` it stays, and the `;` of the list does not cut its end.
    #
    # It works with byte indexes in the text, and reads the last byte of the URL first.
    # A string of one byte, an HTML entity and a bracket make no object.
    # `Validations::Options` checks the options before.
    class Trim # :nodoc: all
      BRACKETS = "()[]{}"

      def initialize(trim:, trim_html_entities:, trim_brackets:)
        one_byte_strings, multibyte_strings = trim.partition { |string| string.bytesize == 1 }
        @one_byte_table = byte_table(one_byte_strings.map(&:ord))
        @bracket_table = byte_table(trim_brackets ? BRACKETS.bytes : [])
        @trim_html_entities = trim_html_entities
        @ending_string_size = EndingStringSize.new(multibyte_strings)
        freeze
      end

      # Returns the end of the URL that stays, of the URL that is the bytes of the text from `start` to `finish`.
      def call(text, start, finish)
        finish = strip(text, start, finish)
        finish = strip_brackets(text, start, finish) if ends_with_bracket?(text, start, finish)

        finish
      end

      private

      def byte_table(bytes)
        table = Array.new(256, false)
        bytes.each { |byte| table[byte] = true }
        table.freeze
      end

      # Removes each string of the list, and each HTML entity, at the end of the URL.
      # Returns the new end of the URL.
      # The loops of this class are `while` loops: a `return` out of a `loop` block makes an object.
      def strip(text, start, finish)
        ending_size = ending_size(text, start, finish)

        until ending_size.zero?
          finish -= ending_size
          ending_size = ending_size(text, start, finish)
        end

        finish
      end

      def ends_with_bracket?(text, start, finish)
        (finish > start) && @bracket_table[text.getbyte(finish - 1)]
      end

      # Removes each bracket with no partner at the end of the URL, and what `strip` removes before it.
      # Each bracket after the last closing bracket with a partner has no partner.
      def strip_brackets(text, start, finish)
        after_last_pair = IndexAfterLastPairedBracket.call(text, start, finish)
        while (finish > after_last_pair) && ends_with_bracket?(text, start, finish)
          finish = strip(text, start, finish - 1)
        end

        finish
      end

      # Returns the count of the bytes to remove from the end of the URL, or 0.
      def ending_size(text, start, finish)
        return 0 if finish == start

        entity_size = EndingEntitySize.call(text, start, finish)
        return (@trim_html_entities ? entity_size : 0) if entity_size.positive?

        string_size = @ending_string_size.call(text, start, finish)
        return string_size if string_size.positive?

        @one_byte_table[text.getbyte(finish - 1)] ? 1 : 0
      end
    end
  end
end
