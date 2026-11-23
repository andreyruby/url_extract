# UrlExtract

Find and extract URLs from plain text:

- Trims punctuation
- Reads non-ASCII URLs, such as `https://ru.wikipedia.org/wiki/Привет`
- Keeps only paired brackets
- Gives the position of each URL
- Reads localhost and IP URLs
- Thread-safe and Ractor-ready
- Linear time, no dependencies

## Usage

```ruby
UrlExtract.scan("See https://example.com/x").map(&:url)
# => ["https://example.com/x"]
```

`UrlExtract.scan` returns an enumerable of the matches, so each `Enumerable` method works:
`each`, `map`, `first(3)`, `to_a`, `count`, `all?` and the others. It reads the text only as far as it needs:
`first(3)` stops at the third URL.

`UrlExtract.(text)` is short for `UrlExtract.scan(text)`:

```ruby
UrlExtract.("See https://example.com/x, https://example.org/y and https://example.net/z").first(2).map(&:url)
# => ["https://example.com/x", "https://example.org/y"]
```

```ruby
UrlExtract.scan("See https://example.com/x").each do |match|
  match.url   # => "https://example.com/x"
  match.range # => 4...25
  match.text  # => "See https://example.com/x"
end
```

To replace URLs, always use `reverse_each`. A replacement changes the length of the text and moves each match
after it; from the last match to the first, each range still points at its URL:

```ruby
text = "See https://example.com/x and https://example.org/y"
UrlExtract.scan(text).reverse_each do |match|
  text[match.range] = %(<a href="#{match.url}">#{match.url}</a>)
end
puts text
# See <a href="https://example.com/x">https://example.com/x</a> and <a href="https://example.org/y">https://example.org/y</a>
```

## Options

The defaults are a great start: try them first, and change an option only when a text needs it.
The options below are the defaults, so this call is the same as `UrlExtract.scan(text)`:

```ruby
text = "See https://example.com/x"
UrlExtract.scan(
  text,
  prefixes: %w[https:// http://],
  max_bytesize: 8000,
  trim: %w[? ! . , : ; * _ ~],
  trim_html_entities: true,
  trim_brackets: true,
  on_encoding_error: :warn
).map(&:url)
# => ["https://example.com/x"]
```

Each option, with examples:

```ruby
# :prefixes - what starts a URL; www. and localhost: only at the start of a word
text = "See www.example.com, localhost:3000/x and https://example.com/x"
UrlExtract.scan(text).map(&:url)
# => ["https://example.com/x"]

UrlExtract.scan(text, prefixes: %w[https:// http:// www. localhost:]).map(&:url)
# => ["www.example.com", "localhost:3000/x", "https://example.com/x"]

# :max_bytesize - the largest URL, in bytes; a longer URL gives no match, and nil sets no limit
UrlExtract.scan("https://example.com/x https://example.com/very/long/path", max_bytesize: 25).map(&:url)
# => ["https://example.com/x"]

UrlExtract.scan("https://example.com/x https://example.com/very/long/path", max_bytesize: nil).map(&:url)
# => ["https://example.com/x", "https://example.com/very/long/path"]

# :trim - the strings to remove from the end of a URL
UrlExtract.scan("See https://example.com/x.", trim: []).map(&:url)
# => ["https://example.com/x."]

UrlExtract.scan("See https://example.com/x...", trim: %w[...]).map(&:url)
# => ["https://example.com/x"]

# :trim_html_entities - false keeps an HTML entity at the end of a URL
UrlExtract.scan("&quot;https://example.com/x&quot;", trim_html_entities: false).map(&:url)
# => ["https://example.com/x&quot;"]

# :trim_brackets - false keeps a bracket with no partner at the end of a URL
UrlExtract.scan("(https://example.com/x)", trim_brackets: false).map(&:url)
# => ["https://example.com/x)"]

# :on_encoding_error - a text not readable as UTF-8 gives no match; :warn also warns
UrlExtract.scan("https://example.com/\xFF").to_a
# => []

UrlExtract.scan("https://example.com/\xFF", on_encoding_error: :skip).to_a
# => []

UrlExtract.scan("https://example.com/\xFF", on_encoding_error: :raise)
# raises UrlExtract::EncodingError
```

## Raised errors

A text that can not be read as UTF-8 raises nothing: it gives no match, and a warning.
`on_encoding_error: :raise` raises `UrlExtract::EncodingError`, an `ArgumentError`:

```ruby
UrlExtract.scan("https://example.com/\xFF", on_encoding_error: :raise)
# UrlExtract::EncodingError: Invalid text: can not be read as UTF-8 (encoding UTF-8, index 20)
# [hint] Provide a valid UTF-8 string
```

A wrong option raises `ArgumentError`, and a text that is not a string raises `TypeError`, each with a hint.

## Corner cases

```ruby
# Punctuation after a URL
UrlExtract.scan("Is it https://example.com/x?!").map(&:url)
# => ["https://example.com/x"]

# Brackets around a URL, and the URL's own brackets
UrlExtract.scan("(See https://en.wikipedia.org/wiki/Ruby_(programming_language))").map(&:url)
# => ["https://en.wikipedia.org/wiki/Ruby_(programming_language)"]

# An HTML entity around a URL
UrlExtract.scan("&quot;https://example.com/x&quot;").map(&:url)
# => ["https://example.com/x"]

# A character reference in a URL, as in an HTML attribute
UrlExtract.scan('<a href="https://example.com/x?a=1&amp;b=2">').map(&:url)
# => ["https://example.com/x?a=1&amp;b=2"]

# Non-ASCII characters
UrlExtract.scan("https://ru.wikipedia.org/wiki/Привет").map(&:url)
# => ["https://ru.wikipedia.org/wiki/Привет"]

# A space that is not ASCII ends a URL
UrlExtract.scan("https://example.com/x\u00A0y").map(&:url)
# => ["https://example.com/x"]

# An IP address or localhost as the host
UrlExtract.scan("Open http://127.0.0.1:8080/x, http://[::1]:3000/ or http://localhost:3000").map(&:url)
# => ["http://127.0.0.1:8080/x", "http://[::1]:3000/", "http://localhost:3000"]

# A scheme in capital letters
UrlExtract.scan("HTTPS://EXAMPLE.COM/x").map(&:url)
# => ["HTTPS://EXAMPLE.COM/x"]

# A URL in a URL is one URL
UrlExtract.scan("https://example.com/x?u=https://example.org/y").map(&:url)
# => ["https://example.com/x?u=https://example.org/y"]

# www. at the start of a word only
UrlExtract.scan("www.example.com xwww.example.org", prefixes: %w[www.]).map(&:url)
# => ["www.example.com"]

# Each URL at each place, with repeats
UrlExtract.scan("https://example.com/x and https://example.com/x").map(&:url)
# => ["https://example.com/x", "https://example.com/x"]

# The first URLs only: reads the text up to the second
UrlExtract.scan("https://example.com https://example.org https://example.net").first(2).map(&:url)
# => ["https://example.com", "https://example.org"]

# A text in another encoding: the range in that text
UrlExtract.scan("Привет https://example.com/путь".encode(Encoding::Windows_1251)).first.range
# => 7...31

# A text with an invalid byte: no match, and a warning
UrlExtract.scan("https://example.com/\xFF").to_a
# => []
```

## Development

Run `bin/setup` to install the dependencies, and `bundle exec rake` to run the specs and Standard.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
