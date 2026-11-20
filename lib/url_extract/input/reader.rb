# frozen_string_literal: true

class UrlExtract
  module Input # :nodoc: all
    # Reads the text of an extractor, and gives each URL in it, with its index in characters.
    #
    # It keeps a frozen copy of the text, so a change of the text during the scan or after it
    # does not change what a match holds. A frozen text needs no copy.
    # A text in an encoding other than UTF-8 loads `Input::Encodings`, which changes `scanned_text`
    # and `each_url` of the class, for each reader after it.
    # A text that the extractor can not read gives no URL, and `EncodingErrorPolicy` says what else it does.
    class Reader # :nodoc: all
      # The frozen text, or nil for a text that the extractor can not read.
      attr_reader :text

      def initialize(text, rules)
        @rules = rules
        @text, @scanned_text = read(text)
      end

      # Gives each URL of the scanned text, and its index in characters.
      # The scan gives byte indexes. In a text of ASCII characters, they are the indexes in characters.
      # In another text, counting the characters between two URLs keeps the time linear.
      def each_url
        text = @scanned_text
        return unless text

        ascii = text.ascii_only?
        character_index = 0
        byte_index = 0

        Scanner.new(text, @rules).call do |url, url_byte_index|
          gap_size = url_byte_index - byte_index
          character_index += ascii ? gap_size : text.byteslice(byte_index, gap_size).length
          byte_index = url_byte_index

          yield url, character_index
        end
      end

      private

      # Returns the text and the text that the scan reads, or nil and nil for a text that the extractor
      # can not read.
      def read(text)
        Validations::Text.check(text)
        text = text.frozen? ? text : text.dup.freeze
        require_relative "encodings" unless Validations::Text.utf8?(text)
        [text, scanned_text(text)]
      rescue UrlExtract::EncodingError => error
        EncodingErrorPolicy.apply(error, @rules.on_encoding_error)
        [nil, nil]
      end

      # The text that the scan reads: the text itself, in UTF-8 or of ASCII characters only.
      def scanned_text(text)
        text
      end
    end
  end
end
