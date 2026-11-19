# UrlExtract

Find and extract URLs from plain text:

- trims what belongs to the text around a URL: `See https://a.com/x.`, `(https://a.com/x)`, `https://a.com/x&quot;`
- keeps paired brackets: `https://en.wikipedia.org/wiki/Ruby_(programming_language)`
- reads non-ASCII URLs, such as `https://ru.wikipedia.org/wiki/Привет`
- optionally reads schemeless URLs (`www.example.com`)
- gives the position of each URL, so the text can be rewritten
- linear time, no dependencies

## Installation

```bash
bundle add url_extract
```

## Usage

```ruby
UrlExtract.urls("See https://a.com/x. Or (http://b.com/y_(z))")
# => ["https://a.com/x", "http://b.com/y_(z)"]

match = UrlExtract.matches("See https://a.com/x.").first
match.url   # => "https://a.com/x"
match.index # => 4
match.range # => 4...19
```

`UrlExtract.matches` returns an extractor: a `UrlExtract`, which is enumerable and lazy.
`UrlExtract.new(text, **options)` makes the same extractor.
`extractor.first(3)` reads the text only up to the third URL.

To replace URLs, go from the last match to the first:

```ruby
text = +"See https://a.com/x and https://b.com/y"
UrlExtract.matches(text).reverse_each { |match| text[match.range] = "<FILTERED>" }
```

### Options

| Option | Default | Meaning |
|---|---|---|
| `schemes` | `%w[https:// http://]` | What starts a URL. `www.` and such match only at the start of a word. |
| `max_size` | `8000` | The largest size of a URL, in bytes. `nil` sets no limit. |
| `trim` | `%w[? ! . , : ; * _ ~]` | The strings to remove from the end of a URL. |
| `trim_html_entities` | `true` | Removes an HTML entity, such as `&quot;`, from the end of a URL. |
| `trim_brackets` | `:unpaired` | Removes a bracket with no partner from the end of a URL. `:none` keeps it. |

```ruby
UrlExtract.urls("Go to www.example.com", schemes: %w[https:// http:// www.])
# => ["www.example.com"]
```

A URL is returned as the text writes it. In HTML it can hold a character reference, such as `&amp;`.

### Encodings

The extractor reads UTF-8. A text in another encoding, such as Windows-1251, Shift_JIS or UTF-16LE,
loads `url_extract/encodings`, which is not loaded by default. The extractor then reads a UTF-8 copy of the text,
and gives each URL in the encoding of the text, with its index in the text:

```ruby
text = "Привет https://a.com/путь.".encode(Encoding::Windows_1251)
match = UrlExtract.matches(text).first
match.url.encoding # => #<Encoding:Windows-1251>
match.index        # => 7
```

A text of ASCII characters only needs no copy, in each encoding. The extractor can not read
a string of bytes that are not ASCII, a dummy encoding such as ISO-2022-JP, or an encoding
that Ruby can not convert to UTF-8.

### Errors

A wrong option, a text with an invalid byte or in an encoding that the extractor can not read raises `ArgumentError`;
a text that is not a string raises `TypeError`. The second line of the message is a hint:

```ruby
UrlExtract.urls(text, scheme: %w[www.])
# ArgumentError: Unknown option :scheme
# [hint] Allowed options: :schemes, :max_size, :trim, :trim_html_entities, :trim_brackets

UrlExtract.urls(text, trim: ".")
# ArgumentError: Invalid value for trim: "." provided
# [hint] Provide array of strings like ["?", "!", ".", ",", ":", ";", "*", "_", "~"]
```

Each string that the extractor can not read as UTF-8 raises `UrlExtract::EncodingError`, an `ArgumentError`,
whatever the cause: an invalid byte, a byte that is no character, or an encoding that the extractor can not convert.
The index points to the character at fault, when one character is at fault:

```ruby
UrlExtract.urls("Привет https://a.com/\xFF")
# UrlExtract::EncodingError: Invalid text: can not be read as UTF-8 (encoding UTF-8, index 21)
# [hint] Provide a valid UTF-8 string
```

## Development

Run `bin/setup` to install the dependencies, and `bundle exec rake` to run the specs and RuboCop.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
