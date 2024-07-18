# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

require 'async/http/server'
require 'async/http/client'
require 'async/http/endpoint'
require 'async/io/shared_endpoint'

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
		@bound_endpoint = Async::IO::SharedEndpoint.bound(endpoint)
		
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
