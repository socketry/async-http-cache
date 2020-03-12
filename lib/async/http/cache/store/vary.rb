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

module Async
	module HTTP
		module Cache
			module Store
				VARY = 'vary'
				ACCEPT_ENCODING = 'accept-encoding'
				
				class Vary
					def initialize(delegate, vary = {})
						@delegate = delegate
						@vary = vary
					end
					
					def close
						@delegate.close
					end
					
					attr :delegate
					
					def normalize(request)
						if accept_encoding = request.headers[ACCEPT_ENCODING]
							if accept_encoding.include?("gzip")
								request.headers.set(ACCEPT_ENCODING, "gzip")
							else
								request.headers.delete(ACCEPT_ENCODING)
							end
						end
					end
					
					def key_for(headers, vary)
						vary.map{|key| headers[key]}
					end
					
					def lookup(key, request)
						if vary = @vary[key]
							# We should provide user-supported normalization here:
							key = key + key_for(request.headers, vary)
						end
						
						return @delegate.lookup(key, request)
					end
					
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
