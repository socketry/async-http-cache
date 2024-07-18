# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

source "https://rubygems.org"

# Specify your gem's dependencies in async-http-cache.gemspec
gemspec

# gem "async-http", path: "../async-http"
# gem "protocol-http", path: "../protocol-http"
# gem "protocol-http1", path: "../protocol-http1"

group :maintenance, optional: true do
	gem "bake-gem"
	gem "bake-modernize"
	
	gem "utopia-project"
end

group :test do
	gem "sus"
	gem "covered"
	gem "decode"
	gem "rubocop"
	
	gem "sus-fixtures-async-http"
	gem "sus-fixtures-console"
	
	gem "bake-test"
	gem "bake-test-external"
end
