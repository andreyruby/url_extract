# frozen_string_literal: true

module UrlExtract
  # Reads the text from its start to its end, and gives each URL to the block, with its byte index.
  #
  # The time is linear in the length of the text: the scan reads the characters after a start one time.
  # It works with byte indexes, and makes one string for each URL: the URL.
  class Scan # :nodoc: all
    # The characters that RFC 3986 allows in a URL, as the content of a regexp character class:
    # - unreserved: letters, digits and `-._~` (https://www.rfc-editor.org/rfc/rfc3986#section-2.3)
    # - reserved: `:/?#[]@` and `!$&'()*+,;=` (https://www.rfc-editor.org/rfc/rfc3986#section-2.2)
    # - `%`, which starts a percent-encoded byte (https://www.rfc-editor.org/rfc/rfc3986#section-2.1)
    # The whole grammar is in https://www.rfc-editor.org/rfc/rfc3986#appendix-A
    RFC3986_CHARACTERS = "A-Za-z0-9\\-._~:/?#\\[\\]@!$&'()*+,;=%"

    # The characters of a URL: the characters of RFC 3986, and each character that is not ASCII and not a space.
    # The URL Standard of browsers allows these: https://url.spec.whatwg.org/#url-code-points
    CHARACTERS = /(?:[#{RFC3986_CHARACTERS}]|[[^\x00-\x7F]&&[^[:space:]]])*/

    # The characters of a URL in a text of ASCII characters only. Such a text gets this shorter regexp,
    # which finds the same URLs there.
    ASCII_CHARACTERS = /[#{RFC3986_CHARACTERS}]*/

    def initialize(text, rules)
      @scanner = StringScanner.new(text)
      @rules = rules
      @characters = text.ascii_only? ? ASCII_CHARACTERS : CHARACTERS
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
      rest_size = @scanner.match?(@characters)
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
