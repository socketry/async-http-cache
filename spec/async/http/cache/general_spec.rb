# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative 'server_context'

require 'async/http/cache/general'

RSpec.shared_examples_for Async::HTTP::Cache::General do
	it "should cache GET requests" do
		response = subject.get("/")
		expect(response.read).to be == "Hello World"
		
		10.times do
			response = subject.get("/")
			expect(response.read).to be == "Hello World"
		end
		
		expect(cache).to have_attributes(count: 10)
	end
	
	it "should cache HEAD requests" do
		response = subject.head("/")
		content_length = response.body.length
		expect(content_length).to be == 11
		expect(response.read).to be_nil
		
		10.times do
			response = subject.head("/")
			expect(response.body.length).to be == content_length
			expect(response.read).to be_nil
		end
		
		expect(cache).to have_attributes(count: 10)
	end
	
	it "should not cache POST requests" do
		response = subject.post("/")
		expect(response.read).to be == "Hello World"
		
		response = subject.post("/")
		expect(response.read).to be == "Hello World"
		
		expect(cache).to have_attributes(count: 0)
	end
	
	context 'with varied response' do
		let(:app) do
			Protocol::HTTP::Middleware.for do |request|
				response = if user_agent = request.headers['user-agent']
					Protocol::HTTP::Response[200, [['cache-control', 'max-age=1, public'], ['vary', 'user-agent']], [user_agent]]
				else
					Protocol::HTTP::Response[200, [['cache-control', 'max-age=1, public'], ['vary', 'user-agent']], ['Hello', ' ', 'World']]
				end
				
				if request.head?
					response.body = Protocol::HTTP::Body::Head.for(response.body)
				end
				
				response
			end
		end
		
		let(:user_agents) {[
			'test-a',
			'test-b',
		]}
		
		it "should cache GET requests" do
			2.times do
				user_agents.each do |user_agent|
					response = subject.get("/", {'user-agent' => user_agent})
					expect(response.headers['vary']).to include('user-agent')
					expect(response.read).to be == user_agent
				end
			end
			
			expect(store.index.size).to be 2
		end
	end
	
	context 'with if-none-match' do
		it 'validate etag' do
			# First, warm up the cache:
			response = subject.get("/")
			expect(response.headers).to_not include('etag')
			expect(response.read).to be == "Hello World"
			expect(response.headers).to include('etag')
			
			etag = response.headers['etag']
			
			response = subject.get("/", {'if-none-match' => etag})
			expect(response).to be_not_modified
		end
	end
end

RSpec.describe Async::HTTP::Cache::General do
	include_context Async::HTTP::Server
	
	let(:app) do
		Protocol::HTTP::Middleware.for do |request|
			body = Async::HTTP::Body::Writable.new(11)
			
			Async do |task|
				body.write "Hello"
				body.write " "
				task.yield
				body.write "World"
				body.close
			rescue Async::HTTP::Body::Writable::Closed
				# Ignore... probably head request.
			end
			
			response = Protocol::HTTP::Response[200, [['cache-control', 'max-age=1, public']], body]
			
			if request.head?
				response.body = Protocol::HTTP::Body::Head.for(response.body)
			end
			
			response
		end
	end
	
	let(:server) do
		Async::HTTP::Server.new(app, endpoint, protocol: protocol)
	end
	
	let(:store) {cache.store.delegate}
	
	context 'with client-side cache' do
		subject(:cache) {described_class.new(client)}
		let(:store) {subject.store.delegate}
		
		include_examples Async::HTTP::Cache::General
	end
	
	context 'with server-side cache via HTTP/1.1' do
		let(:protocol) {Async::HTTP::Protocol::HTTP11}
		
		subject {client}
		
		let(:cache) {described_class.new(app)}
		
		let(:server) do
			Async::HTTP::Server.new(cache, endpoint, protocol: protocol)
		end
		
		include_examples Async::HTTP::Cache::General
	end
	
	context 'with server-side cache via HTTP/2' do
		let(:protocol) {Async::HTTP::Protocol::HTTP2}
			
		subject {client}
		
		let(:cache) {described_class.new(app)}
		
		let(:server) do
			Async::HTTP::Server.new(cache, endpoint, protocol: protocol)
		end
		
		include_examples Async::HTTP::Cache::General
	end
end
