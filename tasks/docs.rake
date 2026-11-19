# frozen_string_literal: true

# Link checking for the documentation files.
module DocsTasks
  # Files checked for broken links
  LINK_FILES = %w[README.md CHANGELOG.md RELEASE.md].freeze

  class << self
    # Headings outside fenced code blocks
    #
    # @param text [String] File contents
    # @return [Array<Array(Integer, String)>] Heading levels with their titles
    def headings(text)
      fenced = false
      text.lines.filter_map do |line|
        fenced = !fenced if line.start_with?("```")
        next if fenced

        match = line.match(/^(\#{1,6})\s+(.+?)\s*$/)
        next unless match

        [match[1].size, match[2]]
      end
    end

    # GitHub anchor for a heading title. Repeated titles get a numeric suffix.
    #
    # @param title [String] Heading title
    # @param seen [Hash] Anchors already generated for the same file
    # @return [String] Anchor without the leading "#"
    def anchor(title, seen)
      base = title.downcase.gsub(/[^\w\s-]/, "").gsub(/\s/, "-")
      count = seen[base]
      seen[base] = count ? count + 1 : 0
      count ? "#{base}-#{count + 1}" : base
    end

    # @param text [String] File contents
    # @return [Array<String>] Anchors of all headings
    def defined_anchors(text)
      seen = {}
      headings(text).map { |_level, title| anchor(title, seen) }
    end

    # @param file [String] Markdown file path
    # @return [Array<String>] Links to missing files and anchors that no heading defines
    def broken_links(file)
      text = File.read(file)
      inline = text.scan(/\]\(([^)\s]+)\)/).flatten
      reference = text.scan(/^\[[^\]]+\]:\s*(\S+)/).flatten

      (inline + reference).uniq.reject { |link| link.match?(/\A\w+:/) || link_valid?(file, link) }
    end

    # @param file [String] Markdown file path
    # @param link [String] Relative link, with an optional anchor
    # @return [Boolean] Whether the linked file and anchor exist
    def link_valid?(file, link)
      path, anchor = link.split("#", 2)
      target = path.empty? ? file : File.join(File.dirname(file), path)
      return false unless File.exist?(target)
      return true if anchor.nil? || !target.end_with?(".md")

      defined_anchors(File.read(target)).include?(anchor)
    end
  end
end

namespace :docs do
  desc "Check all links of the documentation files resolve"
  task :check do
    errors = DocsTasks::LINK_FILES.flat_map do |file|
      DocsTasks.broken_links(file).map { |link| "#{file}: link #{link} matches no file or heading" }
    end

    raise "\n#{errors.join("\n")}" unless errors.empty?

    puts "Documentation links are valid"
  end
end

require "rdoc/task"

# `rake rdoc` writes the documentation site to doc/: the README and the API.
# `rake rdoc:coverage` fails on undocumented public code.
RDoc::Task.new do |rdoc|
  gemspec = Gem::Specification.load("url_extract.gemspec")
  rdoc.rdoc_dir = "doc"
  rdoc.options.concat(gemspec.rdoc_options)
  rdoc.rdoc_files.include(*gemspec.extra_rdoc_files, "lib/**/*.rb")
end
