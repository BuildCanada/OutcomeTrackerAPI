class CommitmentReconciler < Chat
  include Structify::Model

  MODEL = "gemini-3.1-pro-preview"

  after_create { with_model(MODEL, provider: :gemini, assume_exists: true) }

  schema_definition do
    version 1
    name "CommitmentReconciler"
    field :update_existing, :array,
      description: "Existing commitments that have been restated with evolved language, adjusted targets, or updated scope in this document",
      items: {
        type: "object", properties: {
          "existing_commitment_id" => { type: "integer", description: "ID of the existing commitment to update" },
          "new_commitment_title" => { type: "string", description: "Title of the new commitment that restates it" },
          "reason" => { type: "string", description: "Brief explanation of what changed" }
        }
      }
    field :abandoned, :array,
      description: "Existing commitments that appear to have been dropped or abandoned based on this document",
      items: {
        type: "object", properties: {
          "commitment_id" => { type: "integer", description: "ID of the commitment that appears abandoned" },
          "confidence" => { type: "number", description: "Confidence level from 0.0 to 1.0 that this commitment was truly abandoned" },
          "reason" => { type: "string", description: "Brief explanation of why this commitment appears abandoned" }
        }
      }
  end

  def system_prompt
    <<~PROMPT
      You are a government policy analyst detecting when official commitments have been updated or abandoned.

      Be CONSERVATIVE. Minimize false positives. When in doubt, do not flag.

      Two categories:
      1. UPDATE EXISTING — same policy goal restated with adjusted wording, targets, or scope.
         The underlying intent is preserved. Example: spending target increased, program renamed
         and expanded, deadline extended with new scope.
      2. ABANDON — fundamentally different approach or explicitly reversed. The old intent is
         no longer being pursued. Only flag when the document explicitly contradicts or reverses
         a commitment — omission alone is NOT evidence of abandonment.
    PROMPT
  end

  def prompt(new_commitments, existing_commitments)
    new_list = new_commitments.map { |c| "- [NEW] #{c.title}: #{c.description}" }.join("\n")
    existing_list = existing_commitments.map { |c| "- [ID: #{c.id}] #{c.title}: #{c.description}" }.join("\n")

    <<~PROMPT
      A new government source document has been processed. Compare the NEW commitments
      extracted from it against EXISTING active commitments for the same government.

      Identify:
      1. UPDATE EXISTING: An existing commitment restated with evolved language, adjusted
         targets, or updated scope — the same policy goal, just refined.
      2. ABANDONED: An existing commitment that has been explicitly reversed or contradicted
         (omission alone is NOT evidence of abandonment).

      NEW COMMITMENTS FROM THIS DOCUMENT:
      #{new_list}

      EXISTING ACTIVE COMMITMENTS:
      #{existing_list}
    PROMPT
  end
end
