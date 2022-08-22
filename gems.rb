source "https://rubygems.org"

# Specify your gem's dependencies in async-http-cache.gemspec
gemspec

# gem "async-http", path: "../async-http"
# gem "protocol-http", path: "../protocol-http"
# gem "protocol-http1", path: "../protocol-http1"

group :maintenance, optional: true do
	gem "bake-gem"
	gem "bake-modernize"
end

group :test do
	gem "bake-test"
	gem "bake-test-external"
end
