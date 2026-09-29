# frozen_string_literal: true

require "aws-sdk-bedrockruntime"

module DivisionSummaryPipeline
  # Stage 3: the pipeline's only LLM call.
  #
  # The model is used for the one job deterministic code cannot do: understanding a debate well
  # enough to say which procedure it was and where the evidence is (ExtractionPrompt explains
  # what it is asked, ExtractionPayload what it may answer). It is trusted with nothing else. It
  # writes no published text and supplies no facts, and every reference it returns is resolved
  # against Hansard by stage 4 before anything is compiled.
  class SemanticExtractor
    # Shared with the policy classifier, so the two AI features use one region and one set of
    # credentials.
    REGION = DivisionPolicyClassifier::REGION

    # Bedrock's SDK default is 60 seconds, and the larger open-weight models regularly take
    # longer than that to answer a long debate: GLM 5 failed with Net::ReadTimeout on two of the
    # eight test divisions. The SDK retries on a timeout, so a short one wastes minutes as well.
    HTTP_READ_TIMEOUT = 300

    # Lazy callers build one client and share it across models, so nothing contacts AWS at boot
    # or under test.
    def self.bedrock_client
      Aws::BedrockRuntime::Client.new(region: REGION, http_read_timeout: HTTP_READ_TIMEOUT)
    end

    def initialize(model_id = nil, client: nil, llm_caller: nil)
      @model_id = model_id
      @bedrock_client = client
      @llm_caller = llm_caller
    end

    # The model's reply exactly as it came back, which the orchestrator keeps on the saved draft
    # so a reviewer can see what the model actually said.
    def extract_raw(context_packet)
      user_prompt = ExtractionPrompt.user_prompt(context_packet)
      return @llm_caller.call(ExtractionPrompt.system_prompt, user_prompt) if @llm_caller

      call_bedrock(user_prompt)
    end

    # The reply parsed into an ExtractionPayload, or nil if it does not parse.
    def extract(context_packet)
      ExtractionPayload.from_json(extract_raw(context_packet))
    end

    private

    def bedrock_client
      @bedrock_client ||= self.class.bedrock_client
    end

    # Temperature 0 because this is selection, not writing: re-running a division should give as
    # near the same answer as the model allows, so a reviewer can tell a changed draft from a
    # differently-chosen one.
    def call_bedrock(user_prompt)
      response = bedrock_client.converse(
        model_id: @model_id,
        system: [{ text: ExtractionPrompt.system_prompt }],
        messages: [{ role: "user", content: [{ text: user_prompt }] }],
        inference_config: { temperature: 0 }
      )
      response.output.message.content.first.text
    end
  end
end
