# UrlExtract

Find and extract URLs from plain text:

- Trims punctuation
- Reads non-ASCII URLs, such as `https://ru.wikipedia.org/wiki/Привет`
- Keeps only paired brackets
- Gives the position of each URL
- Reads localhost and IP URLs
- Linear time, no dependencies

## Usage

```ruby
UrlExtract.scan("See https://a.com/x.").map(&:url)
# => ["https://a.com/x"]
```

`UrlExtract.scan` returns an enumerable of the matches, so each `Enumerable` method works:
`each`, `map`, `first(3)`, `to_a`, `count`, `all?` and the others. It reads the text only as far as it needs:
`first(3)` stops at the third URL.

`UrlExtract.(text)` is short for `UrlExtract.scan(text)`:

```ruby
UrlExtract.("See https://a.com/x, https://b.com/y and https://c.com/z").first(2).map(&:url)
# => ["https://a.com/x", "https://b.com/y"]
```

```ruby
UrlExtract.scan("See https://a.com/x.").each do |match|
  match.url   # => "https://a.com/x"
  match.range # => 4...19
  match.text  # => "See https://a.com/x."
end
```

To replace URLs, always use `reverse_each`. A replacement changes the length of the text and moves each match
after it; from the last match to the first, each range still points at its URL:

```ruby
text = "See https://a.com/x and https://b.com/y."
UrlExtract.scan(text).reverse_each do |match|
  text[match.range] = %(<a href="#{match.url}">#{match.url}</a>)
end
puts text
# See <a href="https://a.com/x">https://a.com/x</a> and <a href="https://b.com/y">https://b.com/y</a>.
```

## Options

The defaults are a great start: try them first, and change an option only when a text needs it.
The options below are the defaults, so this call is the same as `UrlExtract.scan("See https://a.com/x.")`:

```ruby
UrlExtract.scan(
  "See https://a.com/x.",
  prefixes: %w[https:// http://],
  max_bytesize: 8000,
  trim: %w[? ! . , : ; * _ ~],
  trim_html_entities: true,
  trim_brackets: true,
  on_encoding_error: :warn
).map(&:url)
# => ["https://a.com/x"]
```

Each option, with examples:

```ruby
# :prefixes - what starts a URL; www. and localhost: only at the start of a word
text = "See www.a.com, localhost:3000/x and https://a.com/x"
UrlExtract.scan(text).map(&:url)
# => ["https://a.com/x"]

UrlExtract.scan(text, prefixes: %w[https:// http:// www. localhost:]).map(&:url)
# => ["www.a.com", "localhost:3000/x", "https://a.com/x"]

# :max_bytesize - the largest URL, in bytes; a longer URL gives no match, and nil sets no limit
UrlExtract.scan("https://a.com/x https://a.com/very/long/path", max_bytesize: 20).map(&:url)
# => ["https://a.com/x"]

UrlExtract.scan("https://a.com/x https://a.com/very/long/path", max_bytesize: nil).map(&:url)
# => ["https://a.com/x", "https://a.com/very/long/path"]

# :trim - the strings to remove from the end of a URL
UrlExtract.scan("See https://a.com/x.", trim: []).map(&:url)
# => ["https://a.com/x."]

UrlExtract.scan("See https://a.com/x...", trim: %w[...]).map(&:url)
# => ["https://a.com/x"]

# :trim_html_entities - false keeps an HTML entity at the end of a URL
UrlExtract.scan("&quot;https://a.com/x&quot;", trim_html_entities: false).map(&:url)
# => ["https://a.com/x&quot;"]

# :trim_brackets - false keeps a bracket with no partner at the end of a URL
UrlExtract.scan("(https://a.com/x)", trim_brackets: false).map(&:url)
# => ["https://a.com/x)"]

# :on_encoding_error - a text not readable as UTF-8 gives no match; :warn also warns
UrlExtract.scan("https://a.com/\xFF").to_a
# => []

UrlExtract.scan("https://a.com/\xFF", on_encoding_error: :skip).to_a
# => []

UrlExtract.scan("https://a.com/\xFF", on_encoding_error: :raise)
# raises UrlExtract::EncodingError
```

## Raised errors

A text that can not be read as UTF-8 raises nothing: it gives no match, and a warning.
`on_encoding_error: :raise` raises `UrlExtract::EncodingError`, an `ArgumentError`:

```ruby
UrlExtract.scan("https://a.com/\xFF", on_encoding_error: :raise)
# UrlExtract::EncodingError: Invalid text: can not be read as UTF-8 (encoding UTF-8, index 14)
# [hint] Provide a valid UTF-8 string
```

A wrong option raises `ArgumentError`, and a text that is not a string raises `TypeError`, each with a hint.

## Corner cases

```ruby
# Punctuation after a URL
UrlExtract.scan("Is it https://a.com/x?!").map(&:url)
# => ["https://a.com/x"]

# Brackets around a URL, and the URL's own brackets
UrlExtract.scan("(See https://en.wikipedia.org/wiki/Ruby_(programming_language).)").map(&:url)
# => ["https://en.wikipedia.org/wiki/Ruby_(programming_language)"]

# An HTML entity around a URL
UrlExtract.scan("&quot;https://a.com/x&quot;").map(&:url)
# => ["https://a.com/x"]

# A character reference in a URL, as in an HTML attribute
UrlExtract.scan('<a href="https://a.com/x?a=1&amp;b=2">').map(&:url)
# => ["https://a.com/x?a=1&amp;b=2"]

# Non-ASCII characters
UrlExtract.scan("https://ru.wikipedia.org/wiki/Привет!").map(&:url)
# => ["https://ru.wikipedia.org/wiki/Привет"]

# A space that is not ASCII ends a URL
UrlExtract.scan("https://a.com/x\u00A0y").map(&:url)
# => ["https://a.com/x"]

# An IP address or localhost as the host
UrlExtract.scan("Open http://127.0.0.1:8080/x, http://[::1]:3000/ or http://localhost:3000.").map(&:url)
# => ["http://127.0.0.1:8080/x", "http://[::1]:3000/", "http://localhost:3000"]

# A scheme in capital letters
UrlExtract.scan("HTTPS://A.COM/x").map(&:url)
# => ["HTTPS://A.COM/x"]

# A URL in a URL is one URL
UrlExtract.scan("https://a.com/x?u=https://b.com/y").map(&:url)
# => ["https://a.com/x?u=https://b.com/y"]

# www. at the start of a word only
UrlExtract.scan("www.a.com xwww.b.com", prefixes: %w[www.]).map(&:url)
# => ["www.a.com"]

# Each URL at each place, with repeats
UrlExtract.scan("https://a.com/x and https://a.com/x").map(&:url)
# => ["https://a.com/x", "https://a.com/x"]

# The first URLs only: reads the text up to the second
UrlExtract.scan("https://a.com https://b.com https://c.com").first(2).map(&:url)
# => ["https://a.com", "https://b.com"]

# A text in another encoding: the range in that text
UrlExtract.scan("Привет https://a.com/путь.".encode(Encoding::Windows_1251)).first.range
# => 7...25

# A text with an invalid byte: no match, and a warning
UrlExtract.scan("https://a.com/\xFF").to_a
# => []
```

## Development

Run `bin/setup` to install the dependencies, and `bundle exec rake` to run the specs and Standard.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
