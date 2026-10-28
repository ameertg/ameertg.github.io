source "https://rubygems.org"

# Build locally with:
#
#     bundle exec jekyll serve
#
# Refresh publications from OpenAlex with:
#
#     ruby scripts/fetch_publications.rb
gem "jekyll", "~> 4.4"

group :jekyll_plugins do
  gem "jekyll-feed", "~> 0.17"
end

# Ruby 3+ no longer bundles these.
gem "webrick", "~> 1.8"
gem "csv"
gem "base64"
gem "bigdecimal"
gem "logger"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# and associated library.
install_if -> { RUBY_PLATFORM =~ %r!mingw|mswin|java! } do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end
