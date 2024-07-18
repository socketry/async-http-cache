# Async::HTTP::Cache

Provides a cache middleware for `Async::HTTP` clients and servers.

[![Development Status](https://github.com/socketry/async-http-cache/workflows/Test/badge.svg)](https://github.com/socketry/async-http-cache/actions?workflow=Test)

## Usage

### Client Side

``` ruby
require 'async'
require 'async/http'
require 'async/http/cache'

endpoint = Async::HTTP::Endpoint.parse("https://www.oriontransfer.co.nz")
client = Async::HTTP::Client.new(endpoint)
cache = Async::HTTP::Cache::General.new(client)

Async do
	2.times do
		response = cache.get("/products/index")
		puts response.inspect
		# <Async::HTTP::Protocol::HTTP2::Response ...>
		# <Async::HTTP::Cache::Response ...>
		response.finish
	end
ensure
	cache.close
end
```

## Vary

The `vary` header creates a headache for proxy implementations, because it creates a combinatorial explosion of cache keys, even if the content is the same. Try to avoid it unless absolutely necessary.

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.
