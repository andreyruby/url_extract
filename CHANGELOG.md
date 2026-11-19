# CHANGELOG

## [Unreleased]

- Check the text and each option when a finder is made, and raise an error that
  says what is wrong, with a `[hint]` line of what to provide instead. A text with an
  invalid byte now raises `ArgumentError` when the finder is made, not at its
  first read. A scheme with no `://` that is only letters, such as `https`, an
  empty string in `schemes` or `trim`, and a `max_size` that is not a positive
  integer now raise `ArgumentError`.
- Read a text in another encoding, such as Windows-1251, Shift_JIS or
  UTF-16LE, through a UTF-8 copy: the first such text loads
  `url_extract/encodings`. Each URL is in the encoding of the text. Such a text
  gave wrong URLs before: in Shift_JIS, GBK or Big5, the trim could cut a
  character in half, and UTF-16 raised `Encoding::CompatibilityError`.
- A string of bytes that are not ASCII, a dummy encoding such as ISO-2022-JP,
  and a non-ASCII string of `schemes` or `trim` in an encoding other than UTF-8
  now raise `UrlExtract::EncodingError`, an `ArgumentError`, and so does a text
  with an invalid byte.
- Remove the `ascii_only` option. A URL always takes the characters that are
  not ASCII; a text of ASCII characters only gets the shorter regexp by itself.

## [0.1.0] - 2026-11-19

- Initial release: `UrlExtract.urls`, `UrlExtract.matches` and
  `UrlExtract::Finder`
