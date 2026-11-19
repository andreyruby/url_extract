# CHANGELOG

## [Unreleased]

- Remove the `ascii_only` option. A URL always takes the characters that are
  not ASCII; a text of ASCII characters only gets the shorter regexp by itself.

## [0.1.0] - 2026-11-19

- Initial release: `UrlExtract.urls`, `UrlExtract.matches` and
  `UrlExtract::Finder`
