# frozen_string_literal: true

require "net/http"

# Talks to a model server running on your own machine, in place of Bedrock, through the OpenAI-style
# chat API that llama.cpp's llama-server, Ollama, LM Studio and vLLM all offer. Development only:
# nothing in production calls it. It's for the local tasks in lib/tasks/local_llm.rake: #llm_caller
# is what SemanticExtractor takes, so every other stage of the pipeline runs unchanged.
#
# The defaults suit llama-server on its default port. llama-server's API is documented at
# https://github.com/ggml-org/llama.cpp/tree/master/tools/server
class LocalModelClient
  # A long debate on local hardware can take many minutes just to read the prompt, hence the hour.
  # A small model at temperature 0 can get stuck and never finish: Gemma 4 12B wrote 113,000 tokens
  # for one division before the timeout cut it off. The answer itself is a few hundred tokens of
  # JSON plus any thinking, so the cap turns an hour-long hang into a quick failure.
  DEFAULTS = { "url" => "http://127.0.0.1:8080", "model" => nil, "timeout" => 3600, "max_tokens" => 16_000 }.freeze

  # Seconds to wait for the server to accept a connection. It's on this machine or the local
  # network, so a server that takes longer than this isn't running.
  OPEN_TIMEOUT = 10

  # The server stopped answering. Unlike a reply that can't be used, this says nothing about the
  # division being drafted, so a run stops rather than recording every division left as failed.
  class Unreachable < StandardError; end

  attr_reader :url, :timeout, :max_tokens, :unreachable

  # "local." and the model's name, e.g. local.Qwen3.6-35B-A3B-UD-Q4_K_M: true whichever server is
  # running it, in the "provider.model" style of the Bedrock ids, and never equal to one of them.
  # It's also the folder a run writes its drafts to, so anything but letters, digits, ".", "_" and
  # "-" becomes "-" (Ollama's names have ":" in them).
  def self.model_id_for(name)
    base = File.basename(name.to_s, ".gguf").gsub(/[^A-Za-z0-9._-]/, "-")
    "local.#{base.presence || 'model'}"
  end

  # A reply's answer without any thinking. Reasoning models' thinking normally comes back in
  # reasoning_content; the strip covers a server started with --reasoning-format none.
  def self.answer_text(reply)
    reply.dig("choices", 0, "message", "content").to_s.gsub(%r{<think>.*?</think>}m, "").strip
  end

  def initialize(url:, model: nil, timeout: DEFAULTS["timeout"], max_tokens: DEFAULTS["max_tokens"],
                 replies_dir: Rails.root.join("tmp/llm_replies"))
    @url = url.to_s.chomp("/")
    @model_name = model.presence
    @timeout = timeout
    @max_tokens = max_tokens
    @replies_dir = Pathname(replies_dir)
  end

  # As configured, or else as the server reports it (llama-server reports the GGUF file it loaded).
  # Asking also checks the server is up before a run starts.
  def model_name
    @model_name ||= get_json("/v1/models").dig("data", 0, "id").presence ||
                    raise(Unreachable, "The model server at #{url} has no model loaded")
  end

  def model_id
    self.class.model_id_for(model_name)
  end

  # A callable for SemanticExtractor's llm_caller: (system_prompt, user_prompt) -> the answer's text.
  # Every reply is kept under tmp/llm_replies/, thinking included, with the prompt that produced it
  # beside it, so a failed draft can still be read and replayed (rake ai:replay_reply).
  def llm_caller(division)
    lambda do |system_prompt, user_prompt|
      stamp = "division-#{division.id}-#{Time.current.strftime('%Y%m%d-%H%M%S')}"
      save_prompt(stamp, system_prompt, user_prompt)
      # Temperature 0 to match the Bedrock call. llama-server ignores the model name; Ollama needs it.
      reply = post_json("/v1/chat/completions",
                        model: model_name,
                        messages: [{ role: "system", content: system_prompt }, { role: "user", content: user_prompt }],
                        temperature: 0, max_tokens: max_tokens)
      saved = save_reply(stamp, reply)
      check_completion!(reply, saved)

      self.class.answer_text(reply)
    end
  end

  private

  attr_reader :replies_dir

  # The draft keeps only the prompt of the reply it used, so a sitting day retry's first prompt
  # would otherwise be lost. Written before the request, so one that times out still leaves its
  # prompt to read.
  def save_prompt(stamp, system_prompt, user_prompt)
    FileUtils.mkdir_p(replies_dir)
    File.write(replies_dir.join("#{stamp}-prompt.json"), JSON.pretty_generate(system: system_prompt, user: user_prompt))
  end

  def save_reply(stamp, reply)
    saved = replies_dir.join("#{stamp}.json")
    File.write(saved, JSON.pretty_generate(reply))
    saved.relative_path_from(Rails.root).to_s
  end

  # A reply cut off for length either used up max_tokens or was stopped sooner by the server, when
  # the prompt and the reply together filled its context. The message says
  # which, since only the first is changed in config/local_model.yml.
  def check_completion!(reply, saved)
    return unless reply.dig("choices", 0, "finish_reason") == "length"

    tokens = reply.dig("usage", "completion_tokens") || max_tokens
    cause = tokens >= max_tokens ? "max_tokens in config/local_model.yml" : "the model server's context ran out"
    raise "model wrote #{tokens} tokens without finishing (#{cause}); see #{saved}"
  end

  def get_json(path)
    request(path) { |http, uri| http.get(uri.path) }
  end

  def post_json(path, body)
    request(path) { |http, uri| http.post(uri.path, body.to_json, "Content-Type" => "application/json") }
  end

  # A slow reply (Net::ReadTimeout) belongs to the division being drafted, so it fails only that
  # draft; a server that refuses, never accepts or drops the connection is Unreachable.
  def request(path)
    uri = URI("#{url}#{path}")
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: OPEN_TIMEOUT,
                                                   read_timeout: timeout) do |http|
      yield http, uri
    end
    raise "model server #{response.code}: #{response.body.to_s.truncate(500)}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue SystemCallError, SocketError, Net::OpenTimeout, EOFError => e
    @unreachable = "Can't reach the model server at #{url} (#{e.message})"
    raise Unreachable, @unreachable
  end
end
