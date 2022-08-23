# frozen_string_literal: true

# Copyright, 2020, by Samuel G. D. Williams. <http://www.codeotaku.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'set'
require 'protocol/http/middleware'

require_relative 'body'
require_relative 'response'
require_relative 'store'

module Async
	module HTTP
		module Cache
			class General < ::Protocol::HTTP::Middleware
				CACHE_CONTROL  = 'cache-control'

				CONTENT_TYPE = 'content-type'
				AUTHORIZATION = 'authorization'
				COOKIE = 'cookie'

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

				def cacheable?(request)
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

				def wrap(key, request, response)
					unless CACHEABLE_RESPONSE_CODES.include?(response.status)
						return response
					end

					response_cache_control = response.headers[CACHE_CONTROL]

					if response_cache_control&.no_store? || response_cache_control&.private?
						return response
					end

					if request.head? and body = response.body
						unless body.empty?
							Console.logger.warn(self) {"HEAD request resulted in non-empty body!"}

							return response
						end
					end

					return Body.wrap(response) do |response, body|
						Console.logger.debug(self) {"Updating cache for #{key}..."}
						@store.insert(key, request, Response.new(response, body))
					end
				end

				def call(request)
					key = self.key(request)

					cache_control = request.headers[CACHE_CONTROL]

					unless cache_control&.no_cache?
						if response = @store.lookup(key, request)
							Console.logger.debug(self) {"Cache hit for #{key}..."}
							@count += 1

							# Return the cached response:
							return response
						end
					end

					unless cache_control&.no_store?
						if cacheable?(request)
							return wrap(key, request, super)
						end
					end

					return super
				end
			end
		end
	end
end
