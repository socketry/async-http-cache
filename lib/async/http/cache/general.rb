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
					# We don't support caching requests which have a body:
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
					if response.status != 200
						return response
					end
					
					if request.head? and body = response.body
						unless body.empty?
							Console.logger.warn(self) {"HEAD request resulted in non-empty body!"}
							
							return response
						end
					end
					
					return Body.wrap(response) do |the_response, the_body|
						Console.logger.debug(self) {"Updating cache for #{key}..."}
						@store.insert(key, request, Response.new(the_response, the_body))
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
