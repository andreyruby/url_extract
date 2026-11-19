# UrlExtract

Find and extract URLs from plain text:

- trims what belongs to the text around a URL: `See https://a.com/x.`, `(https://a.com/x)`, `https://a.com/x&quot;`
- keeps paired brackets: `https://en.wikipedia.org/wiki/Ruby_(programming_language)`
- reads non-ASCII URLs, such as `https://ru.wikipedia.org/wiki/Привет`
- optionally reads schemeless URLs (`www.example.com`)
- gives the position of each URL, so the text can be rewritten
- reads texts in other encodings, such as Windows-1251, Shift_JIS or UTF-16LE
- linear time, no dependencies

## Usage

```ruby
UrlExtract.matches("See https://a.com/x.").map(&:url)
# => ["https://a.com/x"]
```

```ruby
UrlExtract.matches("See https://a.com/x.").each do |match|
  match.url
  # => "https://a.com/x"

  match.index
  # => 4

  match.range
  # => 4...19
end
```

To replace URLs, always use `reverse_each`. A replacement changes the length of the text and moves each match
after it; from the last match to the first, each range still points at its URL:

```ruby
text = "See https://a.com/x and https://b.com/y."
UrlExtract.matches(text).reverse_each do |match|
  text[match.range] = %(<a href="#{match.url}">#{match.url}</a>)
end
puts text
# See <a href="https://a.com/x">https://a.com/x</a> and <a href="https://b.com/y">https://b.com/y</a>.
```

## Options

Each option with its default, and `www.` added to the schemes:

```ruby
UrlExtract.matches(
  "Go to www.example.com.",
  schemes: %w[https:// http:// www.], # what starts a URL; www. and such only at the start of a word
  max_size: 8000,                     # the largest URL, in bytes; nil for no limit
  trim: %w[? ! . , : ; * _ ~],        # the strings to remove from the end of a URL
  trim_html_entities: true,           # remove an HTML entity, such as &quot;, from the end of a URL
  trim_brackets: :unpaired,           # remove a bracket with no partner from the end; :none keeps it
  on_encoding_error: :warn            # a text not readable as UTF-8: :warn, :skip or :raise
).map(&:url)
# => ["www.example.com"]
```

## Raised errors

A text that can not be read as UTF-8 raises nothing: it gives no match, and a warning.
`on_encoding_error: :raise` raises `UrlExtract::EncodingError`, an `ArgumentError`:

```ruby
UrlExtract.matches("https://a.com/\xFF", on_encoding_error: :raise)
# UrlExtract::EncodingError: Invalid text: can not be read as UTF-8 (encoding UTF-8, index 14)
# [hint] Provide a valid UTF-8 string
```

A wrong option raises `ArgumentError`, and a text that is not a string raises `TypeError`, each with a hint.

## Corner cases

```ruby
# Punctuation after a URL
UrlExtract.matches("Is it https://a.com/x?!").map(&:url)
# => ["https://a.com/x"]

# Brackets around a URL, and the URL's own brackets
UrlExtract.matches("(See https://en.wikipedia.org/wiki/Ruby_(programming_language).)").map(&:url)
# => ["https://en.wikipedia.org/wiki/Ruby_(programming_language)"]

# An HTML entity around a URL
UrlExtract.matches("&quot;https://a.com/x&quot;").map(&:url)
# => ["https://a.com/x"]

# A character reference in a URL, as in an HTML attribute
UrlExtract.matches('<a href="https://a.com/x?a=1&amp;b=2">').map(&:url)
# => ["https://a.com/x?a=1&amp;b=2"]

# Non-ASCII characters
UrlExtract.matches("https://ru.wikipedia.org/wiki/Привет!").map(&:url)
# => ["https://ru.wikipedia.org/wiki/Привет"]

# A space that is not ASCII ends a URL
UrlExtract.matches("https://a.com/x\u00A0y").map(&:url)
# => ["https://a.com/x"]

# A scheme in capital letters
UrlExtract.matches("HTTPS://A.COM/x").map(&:url)
# => ["HTTPS://A.COM/x"]

# A URL in a URL is one URL
UrlExtract.matches("https://a.com/x?u=https://b.com/y").map(&:url)
# => ["https://a.com/x?u=https://b.com/y"]

# www. at the start of a word only
UrlExtract.matches("www.a.com xwww.b.com", schemes: %w[www.]).map(&:url)
# => ["www.a.com"]

# Each URL at each place, with repeats
UrlExtract.matches("https://a.com/x and https://a.com/x").map(&:url)
# => ["https://a.com/x", "https://a.com/x"]

# The first URLs only: reads the text up to the second
UrlExtract.matches("https://a.com https://b.com https://c.com").first(2).map(&:url)
# => ["https://a.com", "https://b.com"]

# A URL longer than max_size: no match, and no match for a part of it
UrlExtract.matches("https://a.com/x https://a.com/very/long/path", max_size: 20).map(&:url)
# => ["https://a.com/x"]

# A text in another encoding: the index in that text
UrlExtract.matches("Привет https://a.com/путь.".encode(Encoding::Windows_1251)).first.index
# => 7

# A text with an invalid byte: no match, and a warning
UrlExtract.matches("https://a.com/\xFF").to_a
# => []
```

## Development

Run `bin/setup` to install the dependencies, and `bundle exec rake` to run the specs and Standard.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
