# Releases

## Unreleased

  - Improved documentation and agent context.

## v0.4.5

- Modernized gem structure and dependencies.

## v0.4.4

- Modernized gem structure and test suite.
- Added reference to RFC 9111 in documentation.
- Improved cache-ability checks by moving response validation to `General` class.

## v0.4.3

- Improved `Memory` store with configurable limits and pruning intervals.
- Enhanced cache-control header handling for `no-store` and `private` directives.
- Fixed spelling of `cacheable?` method (was `cachable?`).
- Optimized cacheable response code checks using hash table lookup.
- Added external test suite for validation.

## v0.4.2

- Improved memory cache gardener task to be transient with proper annotations.

## v0.4.1

- Updated to use `Console.logger` for consistent logging.
- Modernized gem structure.

## v0.4.0

- **Breaking**: Renamed `trailers` to `trailer` for consistency with HTTP specifications.
- Updated dependency on `async-http`.

## v0.3.0

- Updated dependencies to latest versions.

## v0.2.0

- Added support for ETag validation with `if-none-match` header handling.
- Improved streaming response handling with trailing ETag generation.
- Enhanced trailer support for body digest calculation.
- Removed support for end-of-life Ruby versions.

## v0.1.5

- Fixed handling of responses with `nil` body length to prevent caching errors.

## v0.1.4

- Fixed caching behavior for `HEAD` requests to handle empty bodies correctly.

## v0.1.3

- Updated dependencies.

## v0.1.2

- Improved handling of malformed or missing `cache-control` headers.

## v0.1.1

- Added automatic cache pruning with background gardener task.
- Improved `vary` header handling with better key generation.
- Enhanced request `cache-control` header checking.
- Added detailed cache statistics logging.
- Improved error logging for response failures.

## v0.1.0

- Initial release with HTTP caching middleware.
- Support for `GET` and `HEAD` request caching.
- In-memory cache store with configurable limits.
- Vary header support for content negotiation.
- Cache-control directive compliance.
- Response validation based on status codes and headers.
