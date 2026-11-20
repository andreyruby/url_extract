# frozen_string_literal: true

class UrlExtract
  module Input # :nodoc: all
    # Does what `on_encoding_error` says for a text that the extractor can not read:
    # `:raise` raises the error, `:warn` warns at the line of the caller, and `:skip` says nothing.
    class EncodingErrorPolicy # :nodoc: all
      # The start of the path of each file of the gem. A warning names the first line outside them: the caller's.
      SOURCE_PATH = File.expand_path("..", __dir__)

      class << self
        def apply(error, policy)
          case policy
          when :raise then raise error
          when :warn then warn_at_caller(error)
          end
        end

        private

        # The caller's line, in the form of Ruby's warnings. `uplevel:` counts no C frame, such as `Class#new`,
        # so it can not take an index of `caller_locations`.
        def warn_at_caller(error)
          locations = caller_locations
          caller = locations.find { |location| !location.path.start_with?(SOURCE_PATH) } || locations.last
          warn("#{caller.path}:#{caller.lineno}: warning: url_extract: #{error.message}")
        end
      end
    end
  end
end
