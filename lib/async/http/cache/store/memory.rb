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
				class Memory
					def initialize(limit: 1024, maximum_size: 1024*64, prune_interval: 60)
						@index = {}
						@limit = limit
						@maximum_size = maximum_size
						
						@hit = 0
						@miss = 0
						@pruned = 0
						
						@gardener = Async(transient: true, annotation: self.class) do |task|
							while true
								task.sleep(prune_interval)
								
								pruned = self.prune
								@pruned += pruned
								
								Console.logger.debug(self) do |buffer|
									if pruned > 0
										buffer.puts "Pruned #{pruned} entries."
									end
									
									buffer.puts "Hits: #{@hit} Misses: #{@miss} Pruned: #{@pruned} Ratio: #{(100.0*@hit/@miss).round(2)}%"
									
									body_usage = @index.sum{|key, value| value.body.length}
									buffer.puts "Index size: #{@index.size} Memory usage: #{(body_usage / 1024.0**2).round(2)}MiB"
									
									# @index.each do |key, value|
									# 	buffer.puts "#{key.join('-')}: #{value.body.length}B"
									# end
								end
							end
						end
					end
					
					def close
						@gardener.stop
					end
					
					attr :index
					
					IF_NONE_MATCH = 'if-none-match'
					NOT_MODIFIED = ::Protocol::HTTP::Response[304]
					
					def lookup(key, request)
						if response = @index[key]
							if response.expired?
								@index.delete(key)
								
								@pruned += 1
								
								return nil
							end
							
							if etags = request.headers[IF_NONE_MATCH]
								if etags.include?(response.etag)
									return NOT_MODIFIED
								end
							end
							
							@hit += 1
							
							return response.dup
						else
							@miss += 1
							
							return nil
						end
					end
					
					def insert(key, request, response)
						if @index.size < @limit
							length = response.body&.length
							if length.nil? or length < @maximum_size
								@index[key] = response
							end
						end
					end
					
					# @return [Integer] the number of pruned entries.
					def prune
						initial_count = @index.size
						
						@index.delete_if do |key, value|
							value.expired?
						end
						
						return initial_count - @index.size
					end
				end
			end
		end
	end
end
