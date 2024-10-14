# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

require "protocol/http/response"
require "async/clock"

module Async
	module HTTP
		module Cache
			class Response < ::Protocol::HTTP::Response
				CACHE_CONTROL = "cache-control"
				ETAG = "etag"
				
				X_CACHE = "x-cache"
				
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
				
				def etag
					@etag ||= @headers[ETAG]
				end
				
				def age
					Async::Clock.now - @generated_at
				end
				
				def expired?
					if @max_age
						self.age > @max_age
					end
				end
				
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
