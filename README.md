# UrlExtract

Finds and extracts URLs and links from plain text. An alternative to `URI.extract`:

- trims what belongs to the text around a URL: `See https://a.com/x.`, `(https://a.com/x)`, `https://a.com/x&quot;`
- keeps paired brackets: `https://en.wikipedia.org/wiki/Ruby_(programming_language)`
- reads non-ASCII URLs, and optionally schemeless ones (`www.example.com`)
- gives the position of each URL, so the text can be rewritten
- linear time, no dependencies

## Installation

```bash
bundle add url_extract
```

## Usage

```ruby
require "url_extract"

UrlExtract.urls("See https://a.com/x. Or (http://b.com/y_(z))")
# => ["https://a.com/x", "http://b.com/y_(z)"]

match = UrlExtract.matches("See https://a.com/x.").first
match.url   # => "https://a.com/x"
match.index # => 4
match.range # => 4...19
```

`UrlExtract.matches` returns a `UrlExtract::Finder`, which is enumerable and lazy:
`finder.first(3)` reads the text only up to the third URL.

To replace URLs, go from the last match to the first:

```ruby
text = +"See https://a.com/x and https://b.com/y"
UrlExtract.matches(text).reverse_each { |match| text[match.range] = "<FILTERED>" }
```

### Options

| Option | Default | Meaning |
|---|---|---|
| `schemes` | `%w[https:// http://]` | What starts a URL. `www.` and such match only at the start of a word. |
| `ascii_only` | `false` | `true` takes only the characters of RFC 3986. `false` also takes non-ASCII characters. |
| `max_size` | `8000` | The largest size of a URL, in bytes. `nil` sets no limit. |
| `trim` | `%w[? ! . , : ; * _ ~]` | The strings to remove from the end of a URL. |
| `trim_html_entities` | `true` | Removes an HTML entity, such as `&quot;`, from the end of a URL. |
| `trim_brackets` | `:unpaired` | Removes a bracket with no partner from the end of a URL. `:none` keeps it. |

```ruby
UrlExtract.urls("Go to www.example.com", schemes: %w[https:// http:// www.])
# => ["www.example.com"]
```

### Normalizer

A URL is returned as the text writes it. `UrlExtract::Normalizer` gives the URL that a browser reads from it.
It is optional and needs the `nokogiri` gem:

```ruby
require "url_extract/normalizer"

UrlExtract::Normalizer.call("https://a.com/x?a=1&amp;b=2") # => "https://a.com/x?a=1&b=2"
```

## Development

Run `bin/setup` to install the dependencies, and `bundle exec rake` to run the specs and RuboCop.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
