# frozen_string_literal: true

require_relative "lib/async/http/cache/version"

Gem::Specification.new do |spec|
	spec.name = "async-http-cache"
	spec.version = Async::HTTP::Cache::VERSION
	
	spec.summary = "Standard-compliant cache for async-http."
	spec.authors = ["Samuel Williams", "Colin Kelley", "Olle Jonsson"]
	spec.license = "MIT"
	
	spec.cert_chain  = ["release.cert"]
	spec.signing_key = File.expand_path("~/.gem/release.pem")
	
	spec.homepage = "https://github.com/socketry/async-http-cache"
	
	spec.metadata = {
		"source_code_uri" => "https://github.com/socketry/async-http-cache.git",
	}
	
	spec.files = Dir.glob(["{lib}/**/*", "*.md"], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 3.1"
	
	spec.add_dependency "async-http", "~> 0.56"
end
