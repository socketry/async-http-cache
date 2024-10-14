# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

require_relative "store/memory"
require_relative "store/vary"

module Async
	module HTTP
		module Cache
			module Store
				def self.default
					Vary.new(Memory.new)
				end
			end
		end
	end
end
