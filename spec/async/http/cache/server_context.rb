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

require 'async/http/server'
require 'async/http/client'
require 'async/reactor'

require 'async/io/ssl_socket'
require 'async/http/endpoint'
require 'protocol/http/accept_encoding'

RSpec.shared_context Async::HTTP::Server do
	include_context Async::RSpec::Reactor
	
	let(:protocol) {Async::HTTP::Protocol::HTTP2}
	let(:endpoint) {Async::HTTP::Endpoint.parse('http://127.0.0.1:9294', reuse_port: true)}
	let!(:client) {Async::HTTP::Client.new(endpoint, protocol: protocol)}
	
	let!(:server_task) do
		reactor.async do
			server.run
		end
	end
	
	after(:each) do
		client.close
		server_task.stop
	end
	
	let(:server) do
		Async::HTTP::Server.for(endpoint, protocol) do |request|
			Protocol::HTTP::Response[200, {}, []]
		end
	end
end
