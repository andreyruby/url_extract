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
# Each URL, as the text writes it, with repeats
UrlExtract.matches("See https://a.com/x.").map(&:url)                 # => ["https://a.com/x"]
UrlExtract.matches("Or (http://b.com/y_(z)), then").map(&:url)         # => ["http://b.com/y_(z)"]
UrlExtract.matches("https://a.com/x and https://a.com/x").map(&:url)  # => ["https://a.com/x", "https://a.com/x"]

# Brackets and non-ASCII characters
UrlExtract.matches("See https://en.wikipedia.org/wiki/Ruby_(programming_language).").map(&:url)
# => ["https://en.wikipedia.org/wiki/Ruby_(programming_language)"]
UrlExtract.matches("Статья: https://ru.wikipedia.org/wiki/Привет!").map(&:url)
# => ["https://ru.wikipedia.org/wiki/Привет"]

# The place of a URL
match = UrlExtract.matches("See https://a.com/x.").first
match.url   # => "https://a.com/x"
match.index # => 4
match.range # => 4...19

# Wrap each URL in a link, from the last to the first
text = +"See https://a.com/x and https://b.com/y."
UrlExtract.matches(text).reverse_each do |match|
  text[match.range] = %(<a href="#{match.url}">#{match.url}</a>)
end
puts text
# See <a href="https://a.com/x">https://a.com/x</a> and <a href="https://b.com/y">https://b.com/y</a>.

# The first URLs only: reads the text up to the second
UrlExtract.matches("https://a.com https://b.com https://c.com").first(2).map(&:url)
# => ["https://a.com", "https://b.com"]

# Schemeless URLs, and other schemes
UrlExtract.matches("Go to www.example.com", schemes: %w[https:// http:// www.]).map(&:url)
# => ["www.example.com"]
UrlExtract.matches("Get ftp://a.com/f.zip or write to mailto:me@a.com.", schemes: %w[ftp:// mailto:]).map(&:url)
# => ["ftp://a.com/f.zip", "mailto:me@a.com"]

# What the trim removes
UrlExtract.matches("See https://a.com/x.", trim: []).map(&:url)                  # => ["https://a.com/x."]
UrlExtract.matches("See https://a.com/x...", trim: %w[...]).map(&:url)          # => ["https://a.com/x"]
UrlExtract.matches("(https://a.com/x)", trim_brackets: :none).map(&:url)         # => ["https://a.com/x)"]
UrlExtract.matches("&quot;https://a.com/x&quot;", trim_html_entities: false).map(&:url) # => ["https://a.com/x&quot;"]

# The largest URL, in bytes
UrlExtract.matches("https://a.com/x https://a.com/very/long/path", max_size: 20).map(&:url)
# => ["https://a.com/x"]

# A text in another encoding: each URL in that encoding, at its index in the text
match = UrlExtract.matches("Привет https://a.com/путь.".encode(Encoding::Windows_1251)).first
match.url.encoding # => #<Encoding:Windows-1251>
match.index        # => 7

# A text with an invalid byte: no match, and a warning with a hint
UrlExtract.matches("https://a.com/\xFF").to_a                              # => [], and a warning
UrlExtract.matches("https://a.com/\xFF", on_encoding_error: :skip).to_a   # => []
UrlExtract.matches("https://a.com/\xFF", on_encoding_error: :raise)       # raises UrlExtract::EncodingError
```

## Options

| Option | Default | Meaning |
|---|---|---|
| `schemes` | `%w[https:// http://]` | What starts a URL. `www.` and such match only at the start of a word. |
| `max_size` | `8000` | The largest size of a URL, in bytes. `nil` sets no limit. |
| `trim` | `%w[? ! . , : ; * _ ~]` | The strings to remove from the end of a URL. |
| `trim_html_entities` | `true` | Removes an HTML entity, such as `&quot;`, from the end of a URL. |
| `trim_brackets` | `:unpaired` | Removes a bracket with no partner from the end of a URL. `:none` keeps it. |
| `on_encoding_error` | `:warn` | A text not readable as UTF-8 gives no match, and warns. `:skip`: silently. |

## Development

Run `bin/setup` to install the dependencies, and `bundle exec rake` to run the specs and Standard.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
