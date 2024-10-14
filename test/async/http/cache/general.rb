# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require "sus/fixtures/async/http"
require "async/http/cache/a_general_cache"

describe Async::HTTP::Cache::General do
	include Sus::Fixtures::Async::HTTP::ServerContext

	let(:app) do
		Protocol::HTTP::Middleware.for do |request|
			body = Async::HTTP::Body::Writable.new # (11)
			
			Async do |task|
				body.write "Hello"
				body.write " "
				task.yield
				body.write "World"
				body.close_write
			rescue Async::HTTP::Body::Writable::Closed
				# Ignore... probably head request.
			end
			
			response = Protocol::HTTP::Response[200, [["cache-control", "max-age=1, public"]], body]
			
			if request.head?
				response.body = Protocol::HTTP::Body::Head.for(response.body)
			end
			
			response
		end
	end
	
	let(:store) {cache.store.delegate}
	
	with "client-side cache" do
		let(:cache) {subject.new(@client)}
		alias client cache
		
		let(:store) {client.store.delegate}
		
		it_behaves_like Async::HTTP::Cache::AGeneralCache
	end
	
	with "server-side cache via HTTP/1.1" do
		let(:protocol) {Async::HTTP::Protocol::HTTP11}
		
		let(:cache) {subject.new(app)}
		alias middleware cache
		
		it_behaves_like Async::HTTP::Cache::AGeneralCache
	end
	
	with "server-side cache via HTTP/2" do
		let(:protocol) {Async::HTTP::Protocol::HTTP2}
		
		let(:cache) {subject.new(app)}
		alias middleware cache
		
		it_behaves_like Async::HTTP::Cache::AGeneralCache
	end
end
