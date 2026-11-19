# frozen_string_literal: true

module UrlExtract
  # Returns the byte index after the last closing bracket of a URL that has a partner.
  # Returns `start` when no closing bracket has a partner.
  # The URL is the bytes of the text from `start` to `finish`.
  #
  # A closing bracket has a partner when an opening bracket of its kind is open before it:
  # - `x_(y)` gives the index after the `)`
  # - `x_(y))` gives the index after the first `)`: nothing opens the second
  # - `x)(` gives `start`: the `)` comes before the `(`
  #
  # Each kind of bracket has its own count, so `x([y)]` has two closing brackets with a partner.
  # Each bracket after the returned index has no partner: a closing bracket that nothing opens,
  # or an opening bracket that nothing closes.
  #
  # It reads the bytes of the URL one time, and keeps one count for each kind of bracket.
  # Thus the time is linear, and it makes no object.
  class PairedBracketEnd # :nodoc: all
    ROUND_OPENING = "(".ord
    ROUND_CLOSING = ")".ord
    SQUARE_OPENING = "[".ord
    SQUARE_CLOSING = "]".ord
    CURLY_OPENING = "{".ord
    CURLY_CLOSING = "}".ord

    class << self
      # The counts are locals of one method: an array or an object for them costs an allocation for each URL.
      def call(text, start, finish)
        round_count = square_count = curly_count = 0
        paired_end = start
        index = start

        while index < finish
          case text.getbyte(index)
          when ROUND_OPENING then round_count += 1
          when SQUARE_OPENING then square_count += 1
          when CURLY_OPENING then curly_count += 1
          when ROUND_CLOSING
            if round_count.positive?
              round_count -= 1
              paired_end = index + 1
            end
          when SQUARE_CLOSING
            if square_count.positive?
              square_count -= 1
              paired_end = index + 1
            end
          when CURLY_CLOSING
            if curly_count.positive?
              curly_count -= 1
              paired_end = index + 1
            end
          end

          index += 1
        end

        paired_end
      end
    end
  end
end
