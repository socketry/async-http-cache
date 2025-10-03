# Async::HTTP::Cache

Provides a cache middleware for `Async::HTTP` clients and servers.

[![Development Status](https://github.com/socketry/async-http-cache/workflows/Test/badge.svg)](https://github.com/socketry/async-http-cache/actions?workflow=Test)

## Usage

Please see the [project documentation](https://socketry.github.io/async-http-cache/) for more details.

  - [Getting Started](https://socketry.github.io/async-http-cache/guides/getting-started/index) - This guide explains how to get started with `async-http-cache`, a cache middleware for `Async::HTTP` clients and servers.

## Releases

Please see the [project releases](https://socketry.github.io/async-http-cache/releases/index) for all releases.

### v0.4.6

  - Improved documentation and agent context.

### v0.4.5

  - Modernized gem structure and dependencies.

### v0.4.4

  - Modernized gem structure and test suite.
  - Added reference to RFC 9111 in documentation.
  - Improved cache-ability checks by moving response validation to `General` class.

### v0.4.3

  - Improved `Memory` store with configurable limits and pruning intervals.
  - Enhanced cache-control header handling for `no-store` and `private` directives.
  - Fixed spelling of `cacheable?` method (was `cachable?`).
  - Optimized cacheable response code checks using hash table lookup.
  - Added external test suite for validation.

### v0.4.2

  - Improved memory cache gardener task to be transient with proper annotations.

### v0.4.1

  - Updated to use `Console.logger` for consistent logging.
  - Modernized gem structure.

### v0.4.0

  - **Breaking**: Renamed `trailers` to `trailer` for consistency with HTTP specifications.
  - Updated dependency on `async-http`.

### v0.3.0

  - Updated dependencies to latest versions.

### v0.2.0

  - Added support for ETag validation with `if-none-match` header handling.
  - Improved streaming response handling with trailing ETag generation.
  - Enhanced trailer support for body digest calculation.
  - Removed support for end-of-life Ruby versions.

### v0.1.5

  - Fixed handling of responses with `nil` body length to prevent caching errors.

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
