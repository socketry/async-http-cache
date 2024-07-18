# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.
# Copyright, 2022, by Colin Kelley.

require 'set'
require 'protocol/http/middleware'

require_relative 'body'
require_relative 'response'
require_relative 'store'

module Async
	module HTTP
		module Cache
			# Implements a general shared cache according to https://www.rfc-editor.org/rfc/rfc9111
			class General < ::Protocol::HTTP::Middleware
				CACHE_CONTROL  = 'cache-control'
				
				CONTENT_TYPE = 'content-type'
				AUTHORIZATION = 'authorization'
				COOKIE = 'cookie'
				SET_COOKIE = 'set-cookie'
				
				# Status codes of responses that MAY be stored by a cache or used in reply
				# to a subsequent request.
				#
				# http://tools.ietf.org/html/rfc2616#section-13.4
				CACHEABLE_RESPONSE_CODES = {
					200 => true, # OK
					203 => true, # Non-Authoritative Information
					300 => true, # Multiple Choices
					301 => true, # Moved Permanently
					302 => true, # Found
					404 => true, # Not Found
					410 => true  # Gone
				}.freeze
				
				def initialize(app, store: Store.default)
					super(app)
					
					@count = 0
					
					@store = store
				end
				
				attr :count
				attr :store
				
				def close
					@store.close
				ensure
					super
				end
				
				def key(request)
					@store.normalize(request)
					
					[request.authority, request.method, request.path]
				end
				
				def cacheable_request?(request)
					# We don't support caching requests which have a request body:
					if request.body
						return false
					end
					
					# We can't cache upgraded requests:
					if request.protocol
						return false
					end
					
					# We only support caching GET and HEAD requests:
					unless request.method == 'GET' || request.method == 'HEAD'
						return false
					end
					
					if request.headers[AUTHORIZATION]
						return false
					end
					
					if request.headers[COOKIE]
						return false
					end
					
					# Otherwise, we can cache it:
					return true
				end
				
				def cacheable_response_headers?(headers)
					if cache_control = headers[CACHE_CONTROL]
						if cache_control.no_store? || cache_control.private?
							Console.logger.debug(self, cache_control: cache_control) {"Cannot cache response with cache-control header!"}
							return false
						end
					end
					
					if set_cookie = headers[SET_COOKIE]
						Console.logger.debug(self) {"Cannot cache response with set-cookie header!"}
						return false
					end
								
					return true
				end
				
				def cacheable_response?(response)
					# At this point, we know response.status and response.headers.
					# But we don't know response.body or response.headers.trailer.
					unless CACHEABLE_RESPONSE_CODES.include?(response.status)
						Console.logger.debug(self, status: response.status) {"Cannot cache response with status code!"}
						return false
					end

					unless cacheable_response_headers?(response.headers)
						Console.logger.debug(self) {"Cannot cache response with uncacheable headers!"}
						return false
					end
					
					return true
				end
				
				# Semantically speaking, it is possible for trailers to result in an uncacheable response, so we need to check for that.
				def proceed_with_response_cache?(response)
					if response.headers.trailer?
						unless cacheable_response_headers?(response.headers)
							Console.logger.debug(self, trailer: trailer.keys) {"Cannot cache response with trailer header!"}
							return false
						end
					end
					
					return true
				end
				
				# Potentially wrap the response so that it updates the cache, if caching is possible.
				def wrap(key, request, response)
					if request.head? and body = response.body
						unless body.empty?
							Console.logger.warn(self) {"HEAD request resulted in non-empty body!"}

							return response
						end
					end
					
					unless cacheable_request?(request)
						Console.logger.debug(self) {"Cannot cache request!"}
						return response
					end
					
					unless cacheable_response?(response)
						Console.logger.debug(self) {"Cannot cache response!"}
						return response
					end
					
					return Body.wrap(response) do |response, body|
						if proceed_with_response_cache?(response)
							key ||= self.key(request)
							
							Console.logger.debug(self, key: key) {"Updating miss!"}
							@store.insert(key, request, Response.new(response, body))
						end
					end
				end

				def call(request)
					cache_control = request.headers[CACHE_CONTROL]
					
					unless cache_control&.no_cache?
						key = self.key(request)
						
						if response = @store.lookup(key, request)
							Console.logger.debug(self, key: key) {"Cache hit!"}
							@count += 1
							
							# Return the cached response:
							return response
						end
					end
					
					unless cache_control&.no_store?
						return wrap(key, request, super)
					end
					
					return super
				end
			end
		end
	end
end
