# frozen_string_literal: true

class UrlExtract
  module Trimming # :nodoc: all
    # Returns the count of the bytes of the HTML entity that ends a URL, or 0 when no entity ends it.
    # The URL is the bytes of the text from `start` to `finish`.
    #
    # An entity is `&`, a name and `;`. The name is a letter and 1 to 30 letters or digits, as in `&quot;`,
    # or `#` and 1 to 8 letters or digits, as in `&#39;` and `&#x27;`.
    # The names of HTML are in https://html.spec.whatwg.org/multipage/named-characters.html
    #
    # It reads the bytes from the end of the URL, and makes no object.
    class EntityEnd # :nodoc: all
      SEMICOLON = ";".ord
      AMPERSAND = "&".ord
      NUMBER_SIGN = "#".ord
      MAX_NAME_SIZE = 31
      MAX_NUMBER_SIZE = 8
      LETTER_BYTES = Array.new(256) { |byte| byte.chr.match?(/[a-z]/i) }.freeze
      NAME_BYTES = Array.new(256) { |byte| byte.chr.match?(/[a-z0-9]/i) }.freeze

      class << self
        def call(text, start, finish)
          semicolon_index = finish - 1
          return 0 if text.getbyte(semicolon_index) != SEMICOLON

          name_start = name_start(text, start, semicolon_index)
          entity_start = entity_start(text, start, name_start, semicolon_index - name_start)

          entity_start ? finish - entity_start : 0
        end

        private

        # Returns the index of the first of the letters and digits before the `;`.
        # It reads one byte more than the longest name, so a longer name is no name.
        def name_start(text, start, name_finish)
          first = [start, name_finish - MAX_NAME_SIZE - 1].max
          index = name_finish
          index -= 1 while (index > first) && NAME_BYTES[text.getbyte(index - 1)]
          index
        end

        # Returns the index of the `&` of the entity, or nil when the name is no name of an entity.
        def entity_start(text, start, name_start, name_size)
          index = name_start - 1
          return if index < start

          case text.getbyte(index)
          when AMPERSAND then index if name_size.between?(2, MAX_NAME_SIZE) && LETTER_BYTES[text.getbyte(name_start)]
          when NUMBER_SIGN then number_start(text, start, index - 1) if name_size.between?(1, MAX_NUMBER_SIZE)
          end
        end

        # Returns the index of the `&` before the `#`, or nil.
        def number_start(text, start, index)
          index if (index >= start) && (text.getbyte(index) == AMPERSAND)
        end
      end
    end
  end
end
