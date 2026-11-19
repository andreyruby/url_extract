# frozen_string_literal: true

require_relative "lib/url_extract/version"

Gem::Specification.new do |spec|
  spec.name = "url_extract"
  spec.version = UrlExtract::VERSION
  spec.authors = ["Andrey"]
  spec.email = ["andreyruby@yandex.ru"]

  spec.summary = "Find and extract URLs from plain text"
  spec.description = <<~DESC.tr("\n", " ").strip
    A URL extractor / detector for plain text: finds URLs in a string,
    with their positions. Trims the punctuation, brackets and HTML
    entities around a URL, and reads non-ASCII and www. links. Linear time,
    no runtime dependencies.
  DESC
  spec.homepage = "https://github.com/andreyruby/url_extract"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["documentation_uri"] = "https://andreyruby.github.io/url_extract/"
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/master/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = spec.homepage + "/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb", "sig/**/*.rbs"] << "VERSION" << "README.md" << "LICENSE.txt"
  spec.require_paths = ["lib"]
  spec.extra_rdoc_files = ["README.md"]
  spec.rdoc_options = ["--markup", "markdown", "--main", "README.md", "--title", "UrlExtract"]
end
