# frozen_string_literal: true

# Copyright, 2019, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'async/http/server'
require 'async/http/client'
require 'async/http/endpoint'

require 'io/endpoint'
require 'io/endpoint/host_endpoint'
require 'io/endpoint/ssl_endpoint'
require "io/endpoint/bound_endpoint"
require "io/endpoint/connected_endpoint"

RSpec.shared_context Async::HTTP::Server do
	include_context Async::RSpec::Reactor
	
	let(:protocol) {Async::HTTP::Protocol::HTTP1}
	let(:endpoint) {Async::HTTP::Endpoint.parse('http://127.0.0.1:9294', reuse_port: true, protocol: protocol)}
	
	let(:retries) {1}
	
	let(:app) do
		Protocol::HTTP::Middleware::HelloWorld
	end
	
	let(:middleware) do
		app
	end
	
	let(:server) do
		Async::HTTP::Server.new(middleware, @bound_endpoint)
	end
	
	before do
		# We bind the endpoint before running the server so that we know incoming connections will be accepted:
    @bound_endpoint = IO::Endpoint::BoundEndpoint.bound(endpoint)
		
		# I feel a dedicated class might be better than this hack:
		allow(@bound_endpoint).to receive(:protocol).and_return(endpoint.protocol)
		allow(@bound_endpoint).to receive(:scheme).and_return(endpoint.scheme)
		
		@server_task = Async do
			server.run
		end
		
		@client = Async::HTTP::Client.new(endpoint, retries: retries)
	end
	
	after do
		@client.close
		@server_task.stop
		@bound_endpoint.close
	end
	
	let(:client) {@client}
end
