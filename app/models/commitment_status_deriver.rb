class CommitmentStatusDeriver < Chat
  include Structify::Model

  MODEL = "gemini-3.1-flash-lite-preview"

  after_create { with_model(MODEL, provider: :gemini, assume_exists: true) }

  schema_definition do
    version 1
    name "CommitmentStatusDeriver"
    description "Derives overall commitment status from criteria assessments"
    field :derivation, :object, properties: {
      "recommended_status" => { type: "string", enum: %w[not_started in_progress partially_implemented implemented abandoned] },
      "reasoning" => { type: "string", description: "Explanation of why this status was recommended" },
      "confidence" => { type: "number", description: "0.0 to 1.0" }
    }
  end

  def system_prompt
    "You are a government accountability analyst determining the overall status of a commitment based on its evaluation criteria."
  end

  def prompt(commitment)
    criteria_summary = commitment.criteria.map do |c|
      status_label = c.status
      notes = c.evidence_notes.present? ? "\n    Evidence: #{c.evidence_notes.truncate(300)}" : ""
      "  [#{c.category}] #{c.description}\n    Status: #{status_label}#{notes}"
    end.join("\n\n")

    <<~PROMPT
    Determine the overall status of this government commitment based on its evaluation criteria.

    COMMITMENT:
    Title: #{commitment.title}
    Description: #{commitment.description}
    Type: #{commitment.commitment_type}
    Current Status: #{commitment.status}

    CRITERIA AND THEIR CURRENT ASSESSMENTS:
    #{criteria_summary.presence || "(No criteria assessed yet)"}

    STATUS DEFINITIONS:
    - not_started: No evidence of any action taken on this commitment
    - in_progress: Some action has been taken but the commitment is not yet fulfilled
    - partially_implemented: Significant progress — some success criteria met but not all
    - implemented: All key success/completion criteria are met
    - abandoned: The government has explicitly reversed or dropped this commitment

    RULES:
    - Be conservative. Only recommend a status change if the criteria evidence clearly supports it.
    - Do not recommend "implemented" unless completion and success criteria are largely met.
    - Progress criteria being met (without completion/success) suggests "in_progress".
    - If criteria are mostly "not_assessed", keep status as "not_started" unless there's clear evidence of action.
    - Never recommend "abandoned" unless there is explicit evidence of reversal.
    PROMPT
  end
end
