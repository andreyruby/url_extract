# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in url_extract.gemspec
gemspec

gem "rake", "~> 13.0"
gem "rspec", "~> 3.0", require: false
gem "standard", "~> 1.42", require: false
gem "simplecov", "~> 0.21", require: false
gem "rubocop-rake", "~> 0.6", require: false
gem "rubocop-rspec", "~> 3.2", require: false
gem "rubocop-performance", "~> 1.22", require: false
gem "rubocop-thread_safety", "~> 0.8", require: false
gem "rubocop-packaging", "~> 0.6", require: false
gem "rubocop-md", "~> 2.0", require: false
# Can be used in test like:
#  require 'allocation_stats'
#
#  stats = AllocationStats.trace do
#    subject
#  end
#
#  puts stats.allocations(alias_paths: true).group_by(:sourcefile, :sourceline).to_text
#
gem "allocation_stats", require: false
gem "rdoc", "~> 8.1", require: false
gem "rbs", "~> 4.0", require: false
gem "steep", "~> 2.1", require: false
gem "rubocop-on-rbs", "~> 2.2", require: false
gem "mdl", "~> 0.13", require: false

gem "debug", ">= 1.0"

# For `UrlExtract::Normalizer`, which is optional
gem "nokogiri", ">= 1.12"
