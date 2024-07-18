# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.
# Copyright, 2022, by Colin Kelley.

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
		# HTTP/1 with content length prevents trailers from being sent.
		# Let's get the test suite working and figure out what to do here later.
		# content_length = response.body.length
		# expect(content_length).to be == 11
		expect(response.read).to be_nil

		10.times do
			response = subject.head("/")
			# expect(response.body.length).to be == content_length
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

			expect(store.index.size).to be == 2
		end
	end

	context 'cache writes' do
		context 'by response code' do
			let(:app) do
				Protocol::HTTP::Middleware.for do |_request|
					Protocol::HTTP::Response[response_code, [], ['body']]
				end
			end

			[200, 203, 300, 301, 302, 404, 410].each do |response_code|
				context "when cacheable: #{response_code}" do
					let(:response_code) {response_code}

					it 'is cached' do
						responses = 2.times.map {subject.get("/", {}).tap(&:finish)}
						headers = responses.map {|r| r.headers.to_h}

						expect(headers.first).not_to include('x-cache')
						expect(headers.last).to include('x-cache' => ['hit'])
					end
				end
			end

			[202, 303, 400, 403, 500, 503].each do |response_code|
				context "when not cacheable: #{response_code}" do
					let(:response_code) {response_code}

					it 'is not cached' do
						responses = 2.times.map {subject.get("/", {}).tap(&:finish)}
						response_headers = responses.map {|r| r.headers.to_h}

						expect(response_headers).to be == [{}, {}] # no x-cache: hit
					end
				end
			end
		end

		context 'by cache-control: flag' do
			let(:app) do
				Protocol::HTTP::Middleware.for do |_request|
					Protocol::HTTP::Response[200, headers] # no body?
				end
			end

			['no-store', 'private'].each do |flag|
				let(:headers) {[['cache-control', flag]]}
				let(:headers_hash) {Hash[headers.map {|k, v| [k, [v]]}]}

				context "when not cacheable #{flag}" do
					it 'is not cached' do
						responses = 2.times.map {subject.get("/", {}).tap(&:finish)}
						response_headers = responses.map {|r| r.headers.to_h}

						expect(response_headers).to be == [headers_hash, headers_hash] # no x-cache: hit
					end
				end
			end

			context 'when cacheable' do
				let(:headers) {[]}

				it 'is cached' do
					responses = 2.times.map {subject.get("/", {}).tap(&:finish)}
					headers = responses.map {|r| r.headers.to_h}

					expect(headers).to be == [{}, {"x-cache"=>["hit"]}]
				end
			end
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
			body = Async::HTTP::Body::Writable.new # (11)

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
		let(:middleware) {cache}

		include_examples Async::HTTP::Cache::General
	end

	context 'with server-side cache via HTTP/2' do
		let(:protocol) {Async::HTTP::Protocol::HTTP2}

		subject {client}

		let(:cache) {described_class.new(app)}
		let(:middleware) {cache}

		include_examples Async::HTTP::Cache::General
	end
end
