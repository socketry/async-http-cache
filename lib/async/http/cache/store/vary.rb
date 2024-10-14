# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

module Async
	module HTTP
		module Cache
			module Store
				VARY = "vary"
				ACCEPT_ENCODING = "accept-encoding"
				
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
