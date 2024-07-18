# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020, by Samuel Williams.
# Copyright, 2022, by Colin Kelley.

RSpec.describe Async::HTTP::Cache do
	it "has a version number" do
		expect(Async::HTTP::Cache::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
	end
end
