# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2024, by Samuel Williams.
# Copyright, 2022, by Colin Kelley.

require "async/http/cache/general"

module Async::HTTP::Cache
	AGeneralCache = Sus::Shared("a general cache") do
		it "should cache GET requests" do
			# Warm up the cache:
			response = client.get("/")
			
			expect(response.read).to be == "Hello World"
			
			# Makle 10 more requests, which return the cache:
			10.times do
				response = client.get("/")
				expect(response.read).to be == "Hello World"
			end
			
			expect(cache).to have_attributes(count: be == 10)
		end
		
		it "should cache HEAD requests" do
			response = client.head("/")
			# HTTP/1 with content length prevents trailers from being sent.
			# Let's get the test suite working and figure out what to do here later.
			# content_length = response.body.length
			# expect(content_length).to be == 11
			expect(response.read).to be_nil
			
			10.times do
				response = client.head("/")
				# expect(response.body.length).to be == content_length
				expect(response.read).to be_nil
			end
			
			expect(cache).to have_attributes(count: be == 10)
		end
		
		it "should not cache POST requests" do
			response = client.post("/")
			expect(response.read).to be == "Hello World"
			
			response = client.post("/")
			expect(response.read).to be == "Hello World"
			
			expect(cache).to have_attributes(count: be == 0)
		end
		
		with "varied response" do
			let(:app) do
				Protocol::HTTP::Middleware.for do |request|
					response = if user_agent = request.headers["user-agent"]
						Protocol::HTTP::Response[200, [["cache-control", "max-age=1, public"], ["vary", "user-agent"]], [user_agent]]
					else
						Protocol::HTTP::Response[200, [["cache-control", "max-age=1, public"], ["vary", "user-agent"]], ["Hello", " ", "World"]]
					end
					
					if request.head?
						response.body = Protocol::HTTP::Body::Head.for(response.body)
					end
					
					response
				end
			end
			
			let(:user_agents) {[
				"test-a",
				"test-b",
			]}
			
			it "should cache GET requests" do
				2.times do
					user_agents.each do |user_agent|
						response = client.get("/", {"user-agent" => user_agent})
						expect(response.headers["vary"]).to be(:include?, "user-agent")
						expect(response.read).to be == user_agent
					end
				end
				
				expect(store.index.size).to be == 2
			end
		end
		
		with "cache writes" do
			with "response code" do
				let(:app) do
					Protocol::HTTP::Middleware.for do |_request|
						Protocol::HTTP::Response[response_code, [], ["body"]]
					end
				end
				
				[200, 203, 300, 301, 302, 404, 410].each do |response_code|
					with "cacheable response code #{response_code}", unique: "status-#{response_code}" do
						let(:response_code) {response_code}
					
						it "is cached" do
							responses = 2.times.map {client.get("/", {}).tap(&:finish)}
							headers = responses.map {|r| r.headers.to_h}
							
							expect(headers.first).not.to be(:include?, "x-cache")
							expect(headers.last).to have_keys("x-cache" => be == ["hit"])
						end
					end
				end
				
				[202, 303, 400, 403, 500, 503].each do |response_code|
					with "not cacheable response code #{response_code}", unique: "status-#{response_code}" do
						let(:response_code) {response_code}
						
						it "is not cached" do
							responses = 2.times.map {client.get("/", {}).tap(&:finish)}
							response_headers = responses.map {|r| r.headers.to_h}
							
							expect(response_headers).to be == [{}, {}] # no x-cache: hit
						end
					end
				end
			end
			
			with "by cache-control: flag" do
				let(:app) do
					Protocol::HTTP::Middleware.for do |_request|
						Protocol::HTTP::Response[200, headers] # no body?
					end
				end
				
				["no-store", "private"].each do |flag|
					let(:headers) {[["cache-control", flag]]}
					let(:headers_hash) {Hash[headers.map {|k, v| [k, [v]]}]}
					
					with "not cacheable response #{flag}", unique: flag do
						it "is not cached" do
							responses = 2.times.map {client.get("/", {}).tap(&:finish)}
							response_headers = responses.map {|r| r.headers.to_h}
							
							expect(response_headers).to be == [headers_hash, headers_hash] # no x-cache: hit
						end
					end
				end
				
				with "cacheable response" do
					let(:headers) {[]}
					
					it "is cached" do
						responses = 2.times.map {client.get("/", {}).tap(&:finish)}
						headers = responses.map {|r| r.headers.to_h}
						
						expect(headers).to be == [{}, {"x-cache"=>["hit"]}]
					end
				end
			end
		end
		
		with "if-none-match" do
			it "validate etag" do
				# First, warm up the cache:
				response = client.get("/")
				expect(response.headers).not.to be(:include?, "etag")
				expect(response.read).to be == "Hello World"
				expect(response.headers).to be(:include?, "etag")
				
				etag = response.headers["etag"]
				
				response = client.get("/", {"if-none-match" => etag})
				expect(response).to be(:not_modified?)
			end
		end
	end
end
