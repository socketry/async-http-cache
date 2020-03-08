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
				
				def initialize(app, store: Store.default)
					super(app)
					
					@count = 0
					
					@store = store
					@maximum_length = 128 * 1024
				end
				
				attr :count
				
				def key(request)
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
					
					if request.headers[AUTHORIZATION]
						return false
					end
					
					# We only support caching GET and HEAD requests:
					if request.method == 'GET' || request.method == 'HEAD'
						return true
					end
					
					# Otherwise, we can't cache it:
					return false
				end
				
				def wrap(key, request, response)
					if response.status != 200
						return response
					end
					
					if body = response.body
						if length = body.length
							# Don't cache responses bigger than 128Kb:
							return response if length > @maximum_length
						else
							# Don't cache responses without length:
							return response
						end
					end
					
					return Body.wrap(response) do |message, body|
						@store.insert(key, request, Response.new(message, body))
					end
				end
				
				def call(request)
					key = self.key(request)
					
					cache_control = request.headers[CACHE_CONTROL]
					
					unless cache_control&.no_cache?
						if response = @store.lookup(key, request)
							Async.logger.debug(self) {"Cache hit for #{key}..."}
							@count += 1
							
							# Create a dup of the response:
							return response
						end
					end
					
					unless cache_control&.no_store?
						if cacheable?(request)
							Async.logger.debug(self) {"Updating cache for #{key}..."}
							return wrap(key, request, super)
						end
					end
					
					return super
				end
			end
		end
	end
end
