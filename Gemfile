# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# gem "rails"
gem "openssl"
gem "activerecord"
gem "parallel"
gem "rake"
gem "yaml"
gem "sqlite3"
gem "nokogiri"
gem "tqdm"
gem "descriptive_statistics"
gem "minitest"

unless /hpcguest/.match?(ENV["USER"])
  #gem "pg"
end

group :development do
  gem "rspec-multiprocess_runner"
  gem "standardrb"
  gem "simplecov"
  gem "pry"
end

gem "matrix", "~> 0.4.2"
