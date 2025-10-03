# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require "protocol/http/body/rewindable"
require "protocol/http/body/completable"
require "protocol/http/body/digestable"

require "console"
require "console/event/failure"

module Async
	module HTTP
		module Cache
			module Body
				TRAILER = "trailer"
				ETAG = "etag"
				
				def self.wrap(response, &block)
					if body = response.body
						if body.empty?
							# A body that is empty? at the outset, is immutable. This generally only applies to HEAD requests.
							yield response, body
						else
							# Insert a rewindable body so that we can cache the response body:
							rewindable = ::Protocol::HTTP::Body::Rewindable.wrap(response)
							
							unless response.headers.include?(ETAG)
								# Add the etag header to the trailers:
								response.headers.add(TRAILER, ETAG)
								
								# Compute a digest and add it to the response headers:
								::Protocol::HTTP::Body::Digestable.wrap(response) do |wrapper|
									response.headers.add(ETAG, wrapper.etag)
								end
							end
							
							# Wrap the response with the callback:
							::Protocol::HTTP::Body::Completable.wrap(response) do |error|
								if error
									Console::Event::Failure.for(error).emit(self)
								else
									yield response, rewindable.buffered
								end
							end
						end
					else
						yield response, nil
					end
					
					return response
				end
			end
		end
	end
end
