# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# github-pages (and its commonmarker stack) declares Ruby < 4.0; use Jekyll 4 directly for Ruby 4.x.
gem "jekyll", "~> 4.4"
gem "just-the-docs"
gem "jekyll-include-cache"
gem "jekyll-seo-tag"

group :jekyll_plugins do
  gem "jekyll-feed"
  gem "jekyll-remote-theme"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# and associated library.
install_if -> { RUBY_PLATFORM =~ %r!mingw|mswin|java! } do
  gem "tzinfo"
  gem "tzinfo-data"
end

# Performance-booster for watching directories on Windows
gem "wdm", :install_if => Gem.win_platform?

# kramdown v2 ships without the gfm parser by default. If you're using
# kramdown v1, comment out this line.
gem "kramdown-parser-gfm"

gem "webrick"

# used to be standard library, but not anymore
gem "csv"
gem "bigdecimal"
