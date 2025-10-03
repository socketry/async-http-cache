# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require "protocol/http/response"
require "async/clock"

module Async
	module HTTP
		module Cache
			# Represents a cached HTTP response with cache-specific metadata and functionality.
			class Response < ::Protocol::HTTP::Response
				CACHE_CONTROL = "cache-control"
				ETAG = "etag"
				
				X_CACHE = "x-cache"
				
				# Initialize a new cached response.
				# @parameter response [Protocol::HTTP::Response] The original HTTP response.
				# @parameter body [Protocol::HTTP::Body] The response body.
				def initialize(response, body)
					@generated_at = Async::Clock.now
					
					super(
						response.version,
						response.status,
						response.headers.flatten,
						body,
						response.protocol
					)
					
					@max_age = @headers[CACHE_CONTROL]&.max_age
					@etag = nil
					
					@headers.set(X_CACHE, "hit")
				end
				
				attr :generated_at
				
				# Get the ETag header value for this cached response.
				# @returns [String, nil] The ETag value or nil if not present.
				def etag
					@etag ||= @headers[ETAG]
				end
				
				# Calculate the age of this cached response in seconds.
				# @returns [Float] The number of seconds since the response was generated.
				def age
					Async::Clock.now - @generated_at
				end
				
				# Check if this cached response has expired based on its max-age.
				# @returns [Boolean, nil] True if expired, false if still valid, nil if no max-age set.
				def expired?
					if @max_age
						self.age > @max_age
					end
				end
				
				# Create a duplicate of this cached response with independent body and headers.
				# @returns [Response] A new Response instance with duplicated body and headers.
				def dup
					dup = super
					
					dup.body = @body.dup
					dup.headers = @headers.dup
					
					return dup
				end
			end
		end
	end
end
