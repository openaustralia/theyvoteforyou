# frozen_string_literal: true

require "spec_helper"

describe LocalModelClient do
  let(:replies_dir) { Rails.root.join("tmp/test_llm_replies") }
  let(:client) { described_class.new(url: "http://model.test:8080/", model: "Example-Model-Q4", replies_dir: replies_dir) }
  let(:division) { create(:division) }
  let(:completions) { "http://model.test:8080/v1/chat/completions" }

  after { FileUtils.rm_rf(replies_dir) }

  def reply_body(content, finish_reason: "stop")
    { model: "Example-Model-Q4", choices: [{ message: { content: content }, finish_reason: finish_reason }] }.to_json
  end

  describe ".from_config" do
    let(:path) { Rails.root.join("tmp/test_local_model.yml") }

    after { FileUtils.rm_f(path) }

    it "reads the server's address and the model from the file" do
      File.write(path, "url: http://127.0.0.1:11434\nmodel: example-model\ntimeout: 60\nmax_tokens: 500\n")
      client = described_class.from_config(path)

      expect([client.url, client.model_name, client.timeout, client.max_tokens])
        .to eq ["http://127.0.0.1:11434", "example-model", 60, 500]
    end

    it "uses the defaults for llama-server when there is no file or a setting is left blank" do
      File.write(path, "model:\n")
      client = described_class.from_config(path)

      expect([client.url, client.timeout, client.max_tokens]).to eq ["http://127.0.0.1:8080", 3600, 16_000]
      expect(described_class.from_config(Rails.root.join("tmp/no_such_file.yml")).url).to eq "http://127.0.0.1:8080"
    end
  end

  describe ".model_id_for" do
    it "puts local. before the model's name, without a GGUF file's folder or extension" do
      expect(described_class.model_id_for("/models/Example-Model-UD-Q4_K_M.gguf")).to eq "local.Example-Model-UD-Q4_K_M"
    end

    it "keeps the name safe to use as a folder" do
      expect(described_class.model_id_for("example-model:35b")).to eq "local.example-model-35b"
      expect(described_class.model_id_for(nil)).to eq "local.model"
    end
  end

  describe "#model_name" do
    it "asks the server when none is configured" do
      stub_request(:get, "http://model.test:8080/v1/models")
        .to_return(body: { data: [{ id: "/models/Served-Model-Q4.gguf" }] }.to_json)
      client = described_class.new(url: "http://model.test:8080")

      expect(client.model_id).to eq "local.Served-Model-Q4"
    end

    it "says the server can't be reached when nothing is listening" do
      stub_request(:get, "http://model.test:8080/v1/models").to_raise(Errno::ECONNREFUSED)
      client = described_class.new(url: "http://model.test:8080")

      expect { client.model_name }.to raise_error(described_class::Unreachable, /model.test:8080/)
      expect(client.unreachable).to include "Can't reach the model server"
    end
  end

  describe "#llm_caller" do
    subject(:answer) { client.llm_caller(division).call("the system prompt", "the user prompt") }

    it "asks for the configured model at temperature 0 with the token cap, and returns the answer without thinking" do
      stub_request(:post, completions).to_return(body: reply_body("<think>Hmm.</think>\n{\"answer\": 1}"))

      expect(answer).to eq "{\"answer\": 1}"
      sent = { "model" => "Example-Model-Q4", "temperature" => 0, "max_tokens" => 16_000,
               "messages" => [{ "role" => "system", "content" => "the system prompt" },
                              { "role" => "user", "content" => "the user prompt" }] }
      expect(a_request(:post, completions).with(body: sent)).to have_been_made
    end

    it "keeps every reply, with the prompt that produced it beside it" do
      stub_request(:post, completions).to_return(body: reply_body("{}"))
      answer

      saved = Dir[replies_dir.join("division-#{division.id}-*.json")]
      expect(saved.map { |file| File.basename(file).end_with?("-prompt.json") }).to contain_exactly(false, true)
      expect(JSON.parse(File.read(saved.find { |file| file.end_with?("-prompt.json") })))
        .to eq("system" => "the system prompt", "user" => "the user prompt")
    end

    it "fails when the model runs out of tokens before finishing" do
      stub_request(:post, completions).to_return(body: reply_body("{\"unfinished", finish_reason: "length"))

      expect { answer }.to raise_error(RuntimeError, /16000 tokens without finishing/)
    end

    it "fails on an error from the server without calling it unreachable" do
      stub_request(:post, completions).to_return(status: 500, body: "out of memory")

      expect { answer }.to raise_error(RuntimeError, /model server 500: out of memory/)
      expect(client.unreachable).to be_nil
    end

    it "remembers that the server stopped answering, since every later division would fail the same way" do
      stub_request(:post, completions).to_raise(Errno::ECONNREFUSED)

      expect { answer }.to raise_error(described_class::Unreachable)
      expect(client.unreachable).to include "model.test:8080"
    end
  end
end
