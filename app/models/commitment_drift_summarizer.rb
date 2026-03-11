class CommitmentDriftSummarizer < Chat
  include Structify::Model

  MODEL = "gemini-3.1-flash-lite-preview"

  after_create { with_model(MODEL, provider: :gemini, assume_exists: true) }

  schema_definition do
    version 1
    name "CommitmentDriftSummarizer"
    field :change_summary, :string,
      description: "A 1-3 sentence human-readable summary of what changed and why it matters"
  end

  def system_prompt
    "You are a government policy analyst summarizing changes to official commitments. " \
      "Be concise and factual. Focus on what changed and its significance."
  end

  def prompt(old_values, new_values)
    <<~PROMPT
      A government commitment has been updated in a new source document.
      Summarize what changed and why it matters in 1-3 sentences.

      PREVIOUS VERSION:
      Title: #{old_values[:title]}
      Description: #{old_values[:description]}
      Original text: #{old_values[:original_text]}

      NEW VERSION:
      Title: #{new_values[:title]}
      Description: #{new_values[:description]}
      Original text: #{new_values[:original_text]}
    PROMPT
  end
end
