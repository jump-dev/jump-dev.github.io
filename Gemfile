source "https://rubygems.org"

# Hello! This is where you manage which Jekyll version is used to run.
# When you want to use a different version, change it below, save the
# file and run `bundle install`. Run Jekyll with `bundle exec`, like so:
#
#     bundle exec jekyll serve
#

# See https://github.com/jekyll/jekyll/issues/9544
gem "jekyll", "~>3.9.3"

# This is the default theme for new Jekyll sites. You may change this to anything you like.
gem "minima", "~> 2"

gem "jekyll-remote-theme"

group :jekyll_plugins do
  # Pinned to v228 because of https://github.com/jekyll/jekyll/issues/9544
  gem "github-pages", "= 228"
  gem "jekyll-feed", "~> 0.6"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Performance-booster for watching directories on Windows
gem "wdm", "~> 0.1.0" if Gem.win_platform?

gem "jekyll-include-cache", "~> 0.2.0"
