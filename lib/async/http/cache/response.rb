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

require 'protocol/http/response'
require 'async/clock'

module Async
	module HTTP
		module Cache
			class Response < ::Protocol::HTTP::Response
				CACHE_CONTROL = 'cache-control'
				SET_COOKIE = 'set-cookie'
				ETAG = 'etag'
				
				X_CACHE = 'x-cache'
				
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
					
					@headers.set(X_CACHE, 'hit')
				end
				
				attr :generated_at
				
				def etag
					@etag ||= @headers[ETAG]
				end
				
				def cacheable?
					if cache_control = @headers[CACHE_CONTROL]
						if cache_control.private? || !cache_control.public?
							return false
						end
					else
						# No cache control header...
						return false
					end
					
					if set_cookie = @headers[SET_COOKIE]
						Console.logger.warn(self) {"Cannot cache response with set-cookie header!"}
						return false
					end
					
					return true
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
