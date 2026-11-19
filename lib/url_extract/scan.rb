# frozen_string_literal: true

module UrlExtract
  # Reads the text from its start to its end, and gives each URL to the block, with its byte index.
  #
  # The time is linear in the length of the text: the scan reads the characters after a start one time.
  # It works with byte indexes, and makes one string for each URL: the URL.
  class Scan # :nodoc: all
    def initialize(text, rules)
      @scanner = StringScanner.new(text)
      @rules = rules
    end

    def call(&)
      start = @rules.start
      return unless start

      scan_url(&) while @scanner.skip_until(start)
    end

    private

    def scan_url
      start_size = @scanner.matched_size
      byte_index = @scanner.pos - start_size
      rest_size = @scanner.match?(@rules.characters)
      text = @scanner.string
      size = @rules.trim.call(text, byte_index, start_size + rest_size)
      return skip_rest(rest_size) if (size <= start_size) || (size > @rules.max_size)

      @scanner.pos = byte_index + size
      yield(text.byteslice(byte_index, size), byte_index)
    end

    # The trim removed each character after the start, or the URL is longer than the limit, so no URL is there.
    # The scan goes on after these characters. Reading them again for each start in them takes a time
    # that grows with the square of their count.
    def skip_rest(rest_size)
      @scanner.pos += rest_size
    end
  end
end
