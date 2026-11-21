# frozen_string_literal: true

# Before its first request, the Elasticsearch client checks it's talking to Elasticsearch, and remembers the answer
# for the rest of the run. CI has no Elasticsearch to answer, so a spec that left this to itself would pass or fail
# depending on whether an earlier spec had answered it. Answering it for every spec removes that trap; each spec
# still stubs the requests it makes.
ELASTICSEARCH_ROOT = URI.join(ENV.fetch("ELASTICSEARCH_URL", "http://localhost:9200"), "/").to_s

RSpec.configure do |config|
  config.before do
    stub_request(:get, ELASTICSEARCH_ROOT).to_return(
      headers: { "Content-Type" => "application/json", "X-Elastic-Product" => "Elasticsearch" },
      body: { version: { number: "7.17.7" }, tagline: "You Know, for Search" }.to_json
    )
  end
end
