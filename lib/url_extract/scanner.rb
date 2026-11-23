# frozen_string_literal: true

class UrlExtract
  # Reads the text from its start to its end, and gives each URL to the block, with its byte index.
  #
  # The time is linear in the length of the text: the scan reads the characters after a prefix one time.
  # It works with byte indexes, and makes one string for each URL: the URL.
  class Scanner # :nodoc: all
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

    def each_url(&)
      prefix_regexp = @rules.prefix_regexp
      return unless prefix_regexp

      scan_url(&) while @scanner.skip_until(prefix_regexp)
    end

    private

    def scan_url
      prefix_finish = @scanner.pos
      byte_index = prefix_finish - @scanner.matched_size
      rest_size = @scanner.match?(@characters)
      text = @scanner.string
      finish = @rules.trim.call(text, byte_index, prefix_finish + rest_size)
      size = finish - byte_index
      return skip_rest(rest_size) if (finish <= prefix_finish) || (size > @rules.max_bytesize)

      @scanner.pos = finish
      yield(text.byteslice(byte_index, size), byte_index)
    end

    # The trim removed each character after the prefix, or the URL is longer than the limit, so no URL is there.
    # The scan goes on after these characters. Reading them again for each prefix in them takes a time
    # that grows with the square of their count.
    def skip_rest(rest_size)
      @scanner.pos += rest_size
    end
  end
end
