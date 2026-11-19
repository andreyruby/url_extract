# frozen_string_literal: true

module UrlExtract
  # Finds how much of a URL in a text stays, when the end of the URL belongs to the text around it. It removes:
  # - each string of the list, such as the dot of `See https://a.com/x.`
  # - with `trim_html_entities`, an HTML entity, such as the `&quot;` of `https://a.com/x&quot;`
  # - with the brackets `:unpaired`, a bracket with no partner, as `PairedBracketEnd` says:
  #   the `)` of `(https://a.com/x)` and the `(` of `https://a.com/x( see)`. A bracket with a partner stays,
  #   as in `https://a.com/x_(y)`.
  #
  # It repeats these until the last character of the URL stays.
  # An HTML entity is one unit: without `trim_html_entities` it stays, and the `;` of the list does not cut its end.
  #
  # It works with byte indexes in the text, and reads the last byte of the URL first.
  # A string of one byte, an HTML entity and a bracket make no object.
  # `UrlExtract::Validate` checks the options before.
  class Trim # :nodoc: all
    BRACKETS = {unpaired: "()[]{}", none: ""}.freeze

    def initialize(trim:, trim_html_entities:, trim_brackets:)
      one_byte_strings, long_strings = trim.partition { |string| string.bytesize == 1 }
      @string_bytes = byte_table(one_byte_strings.map(&:ord))
      @bracket_bytes = byte_table(bracket_bytes(trim_brackets))
      @html_entities = trim_html_entities
      @long_string_end_size = UrlExtract::LongStringEndSize.new(long_strings)
    end

    # Returns the count of the bytes that stay, of the `size` bytes of the URL at `byte_index` of the text.
    def call(text, byte_index, size)
      finish = byte_index + size
      kept_finish = strip(text, byte_index, finish)
      kept_finish = strip_brackets(text, byte_index, kept_finish) if bracket_end?(text, byte_index, kept_finish)

      kept_finish - byte_index
    end

    private

    def bracket_bytes(brackets)
      BRACKETS.fetch(brackets).bytes
    end

    def byte_table(bytes)
      table = Array.new(256, false)
      bytes.each { |byte| table[byte] = true }
      table
    end

    # Removes each string of the list, and each HTML entity, at the end of the URL.
    # Returns the new end of the URL.
    # The loops of this class are `while` loops: a `return` out of a `loop` block makes an object.
    def strip(text, start, finish)
      removed_size = removed_size(text, start, finish)

      until removed_size.zero?
        finish -= removed_size
        removed_size = removed_size(text, start, finish)
      end

      finish
    end

    def bracket_end?(text, start, finish)
      (finish > start) && @bracket_bytes[text.getbyte(finish - 1)]
    end

    # Removes each bracket with no partner at the end of the URL, and what `strip` removes before it.
    # Each bracket after the last closing bracket with a partner has no partner.
    def strip_brackets(text, start, finish)
      paired_end = UrlExtract::PairedBracketEnd.call(text, start, finish)
      finish = strip(text, start, finish - 1) while (finish > paired_end) && bracket_end?(text, start, finish)

      finish
    end

    # Returns the count of the bytes to remove from the end of the URL, or 0.
    def removed_size(text, start, finish)
      return 0 if finish == start

      entity_size = UrlExtract::EntityEndSize.call(text, start, finish)
      return (@html_entities ? entity_size : 0) if entity_size.positive?

      long_string_size = @long_string_end_size.call(text, start, finish)
      return long_string_size if long_string_size.positive?

      @string_bytes[text.getbyte(finish - 1)] ? 1 : 0
    end
  end
end
