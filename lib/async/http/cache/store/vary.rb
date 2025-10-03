# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

module Async
	module HTTP
		module Cache
			module Store
				VARY = "vary"
				ACCEPT_ENCODING = "accept-encoding"
				
				# Represents a cache store wrapper that handles HTTP Vary header functionality.
				class Vary
					# Initialize a new Vary store wrapper.
					# @parameter delegate [Store] The underlying cache store to delegate to.
					# @parameter vary [Hash] Initial vary header mappings.
					def initialize(delegate, vary = {})
						@delegate = delegate
						@vary = vary
					end
					
					# Close the vary store and its delegate.
					def close
						@delegate.close
					end
					
					attr :delegate
					
					# Normalize request headers to reduce cache key variations.
					# @parameter request [Protocol::HTTP::Request] The HTTP request to normalize.
					def normalize(request)
						if accept_encoding = request.headers[ACCEPT_ENCODING]
							if accept_encoding.include?("gzip")
								request.headers.set(ACCEPT_ENCODING, "gzip")
							else
								request.headers.delete(ACCEPT_ENCODING)
							end
						end
					end
					
					# Generate vary-specific key components from request headers.
					# @parameter headers [Protocol::HTTP::Headers] The request headers.
					# @parameter vary [Array] Array of header names that affect caching.
					# @returns [Array] Array of header values for the vary keys.
					def key_for(headers, vary)
						vary.map{|key| headers[key]}
					end
					
					# Look up a cached response, accounting for vary headers.
					# @parameter key [Array] The base cache key.
					# @parameter request [Protocol::HTTP::Request] The HTTP request.
					# @returns [Protocol::HTTP::Response, nil] The cached response or nil if not found.
					def lookup(key, request)
						if vary = @vary[key]
							# We should provide user-supported normalization here:
							key = key + key_for(request.headers, vary)
						end
						
						return @delegate.lookup(key, request)
					end
					
					# Insert a response into the cache, handling vary headers appropriately.
					# @parameter key [Array] The base cache key.
					# @parameter request [Protocol::HTTP::Request] The HTTP request.
					# @parameter response [Protocol::HTTP::Response] The HTTP response to cache.
					def insert(key, request, response)
						if vary = response.headers[VARY]&.sort
							@vary[key] = vary
							
							key = key + key_for(request.headers, vary)
						end
						
						@delegate.insert(key, request, response)
					end
				end
			end
		end
	end
end
