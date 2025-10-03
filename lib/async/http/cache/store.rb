# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require_relative "store/memory"
require_relative "store/vary"

module Async
	module HTTP
		module Cache
			# Provides cache storage implementations and utilities.
			module Store
				# Create a default cache store with Vary support over an in-memory store.
				# @returns [Store::Vary] A default cache store instance.
				def self.default
					Vary.new(Memory.new)
				end
			end
		end
	end
end
