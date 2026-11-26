# frozen_string_literal: true

class UrlExtract
  module Validations # :nodoc: all
    # Raises the error of a value that the extractor can not take. Its message has two lines: what is wrong,
    # and a short hint of what to provide.
    #
    #   Invalid value for trim: "." provided
    #   [hint] Provide array of strings like ["?", "!", ".", ",", ":", ";", "*", "_", "~", "'", "’", "”", "»", "›"]
    class Failure # :nodoc: all
      # The longest part of a wrong value that an error shows. The value can be a long text, given by mistake.
      MAX_SHOWN_SIZE = 60

      class << self
        def fail_with(message, hint, error_class: ArgumentError)
          raise error_class, "#{message}\n[hint] #{hint}"
        end

        # Shows a value in a message: the result of `inspect`, cut to `MAX_SHOWN_SIZE` characters.
        def show(value)
          shown = value.inspect
          (shown.length > MAX_SHOWN_SIZE) ? "#{shown[0, MAX_SHOWN_SIZE]}..." : shown
        end
      end
    end
  end
end
