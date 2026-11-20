# frozen_string_literal: true

# Loads the reading of a text in an encoding other than UTF-8 ahead. `UrlExtract.new` loads it
# when it first gets such a text. `UrlExtract::Input::Encodings` describes it.
require_relative "../url_extract"
require_relative "input/encodings"
