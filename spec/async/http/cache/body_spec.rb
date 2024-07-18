# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020, by Samuel Williams.

require 'async/http/cache/body'

RSpec.describe Async::HTTP::Cache::Body do
	include_context RSpec::Memory
	
	let(:body) {Protocol::HTTP::Body::Buffered.new(["Hello", "World"])}
	let(:response) {Protocol::HTTP::Response[200, [], body]}
	
	describe ".wrap" do
		it "can buffer and stream bodies" do
			invoked = false
			
			described_class.wrap(response) do |response, body|
				invoked = true
				
				# The cached/buffered body:
				expect(body.read).to be == "Hello"
				expect(body.read).to be == "World"
				expect(body.read).to be nil
			end
			
			body = response.body
			
			# The actual body:
			expect(body.read).to be == "Hello"
			expect(body.read).to be == "World"
			expect(body.read).to be nil
			
			body.close
			
			expect(invoked).to be true
		end
		
		it "ignores failed responses" do
			invoked = false
			
			described_class.wrap(response) do
				invoked = true
			end
			
			body = response.body
			
			expect(body.read).to be == "Hello"
			
			body.close(IOError.new("failed"))
			
			expect(invoked).to be false
		end
	end
end
