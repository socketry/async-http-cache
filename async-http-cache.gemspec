
require_relative 'lib/async/http/cache/version'

Gem::Specification.new do |spec|
	spec.name = "async-http-cache"
	spec.version = Async::HTTP::Cache::VERSION
	spec.authors = ["Samuel Williams"]
	spec.email = ["samuel.williams@oriontransfer.co.nz"]
	
	spec.summary = "Standard-compliant cache for async-http."
	spec.homepage = "https://github.com/socketry/async-http-cache"
	spec.license = "MIT"
	
	spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")
	
	# Specify which files should be added to the gem when it is released.
	# The `git ls-files -z` loads the files in the RubyGem that have been added into git.
	spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
		`git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
	end
	
	spec.require_paths = ["lib"]
	
	spec.add_dependency "async-http"
	spec.add_dependency "protocol-http", "~> 0.14.2"
	
	spec.add_development_dependency "async-rspec", "~> 1.10"
	
	spec.add_development_dependency "covered"
	spec.add_development_dependency "bundler"
	spec.add_development_dependency "rspec"
	spec.add_development_dependency "rake"
end
