
RSpec.describe Async::HTTP::Cache do
	it "has a version number" do
		expect(Async::HTTP::Cache::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
	end
end
