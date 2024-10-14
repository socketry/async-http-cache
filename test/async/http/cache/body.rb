# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.

require "async/http/cache/body"
require "protocol/http"

require "sus/fixtures/console"

describe Async::HTTP::Cache::Body do
	include_context Sus::Fixtures::Console::CapturedLogger
	
	let(:body) {Protocol::HTTP::Body::Buffered.new(["Hello", "World"])}
	let(:response) {Protocol::HTTP::Response[200, [], body]}
	
	with ".wrap" do
		it "can buffer and stream bodies" do
			invoked = false
			
			subject.wrap(response) do |response, body|
				invoked = true
				
				# The cached/buffered body:
				expect(body.read).to be == "Hello"
				expect(body.read).to be == "World"
				expect(body.read).to be_nil
			end
			
			body = response.body
			
			# The actual body:
			expect(body.read).to be == "Hello"
			expect(body.read).to be == "World"
			expect(body.read).to be_nil
			
			body.close
			
			expect(invoked).to be == true
		end
		
		it "ignores failed responses" do
			invoked = false
			
			subject.wrap(response) do
				invoked = true
			end
			
			body = response.body
			
			expect(body.read).to be == "Hello"
			
			body.close(IOError.new("expected failure"))
			
			expect(invoked).to be == false
			
			expect_console.to have_logged(
				severity: be == :error,
				event: have_keys(message: be =~ /expected failure/)
			)
		end
	end
end
