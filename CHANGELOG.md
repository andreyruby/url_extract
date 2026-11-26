# CHANGELOG

## [Unreleased]

- The default `trim` list removes the closing quotes `'`, `’`, `”`, `»` and `›` from the end of a URL.
  A quote inside a URL stays, as in `https://en.wikipedia.org/wiki/Hawai'i`.

## [0.1.0] - 2026-11-26

- Initial release: `UrlExtract.scan` (or `UrlExtract.(text)`) and `UrlExtract.new` find each URL
  in a plain text, with its position. They trim punctuation, keep only paired brackets, and read non-ASCII,
  localhost and IP URLs, in linear time with no dependencies.
- `url_extract/encodings` reads a text in an encoding other than UTF-8. It loads only for such a text.
