# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

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
					
					IF_NONE_MATCH = "if-none-match"
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
