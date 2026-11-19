# CHANGELOG

## [Unreleased]

- Check the text and each option when a finder is made, and raise an error that
  says what is wrong, with a `[hint]` line of what to provide instead. A text with an
  invalid byte now raises `ArgumentError` when the finder is made, not at its
  first read. A scheme with no `://` that is only letters, such as `https`, an
  empty string in `schemes` or `trim`, and a `max_size` that is not a positive
  integer now raise `ArgumentError`.
- Read a text in UTF-8, or of ASCII characters only. A text in another
  encoding, such as Windows-1251 or a string of bytes that are not ASCII, now
  raises `ArgumentError`, and so does a non-ASCII string of `schemes` or `trim`
  in another encoding. Such a text gave wrong URLs before: in Shift_JIS, GBK
  or Big5, the trim could cut a character in half.
- Remove the `ascii_only` option. A URL always takes the characters that are
  not ASCII; a text of ASCII characters only gets the shorter regexp by itself.

## [0.1.0] - 2026-11-19

- Initial release: `UrlExtract.urls`, `UrlExtract.matches` and
  `UrlExtract::Finder`
