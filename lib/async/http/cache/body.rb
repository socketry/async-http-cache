# frozen_string_literal: true
#
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

require 'protocol/http/body/rewindable'
require 'protocol/http/body/completable'
require 'protocol/http/body/digestable'

module Async
	module HTTP
		module Cache
			module Body
				TRAILER = 'trailer'
				ETAG = 'etag'
				
				def self.wrap(response, &block)
					if body = response.body
						if body.empty?
							# A body that is empty? at the outset, is immutable. This generally only applies to HEAD requests.
							yield response, body
						else
							# Insert a rewindable body so that we can cache the response body:
							rewindable = ::Protocol::HTTP::Body::Rewindable.wrap(response)
							
							unless response.headers.include?(ETAG)
								# Compute a digest and add it to the response headers:
								::Protocol::HTTP::Body::Digestable.wrap(response) do |wrapper|
									response.headers.add(ETAG, wrapper.etag)
								end
								
								# Ensure the etag is listed as a trailer:
								response.headers.add(TRAILER, ETAG)
							end
							
							# Wrap the response with the callback:
							::Protocol::HTTP::Body::Completable.wrap(response) do |error|
								if error
									Console.logger.error(self) {error}
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
