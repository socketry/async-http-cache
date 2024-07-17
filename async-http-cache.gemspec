# frozen_string_literal: true

require_relative "lib/async/http/cache/version"

Gem::Specification.new do |spec|
	spec.name = "async-http-cache"
	spec.version = Async::HTTP::Cache::VERSION
	
	spec.summary = "Standard-compliant cache for async-http."
	spec.authors = ["Samuel Williams", "Olle Jonsson"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/socketry/async-http-cache"
	
	spec.files = Dir.glob('{lib}/**/*', File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 2.3.0"
	
	spec.add_dependency "async-http", ">= 0.65"
	
  spec.add_development_dependency "io-endpoint"
	spec.add_development_dependency "async-rspec", "~> 1.10"
	spec.add_development_dependency "covered"
	spec.add_development_dependency "rspec"
end
