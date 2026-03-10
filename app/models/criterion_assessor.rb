class CriterionAssessor < Chat
  include Structify::Model

  MODEL = "gemini-3.1-pro-preview"

  after_create { with_model(MODEL, provider: :gemini, assume_exists: true) }

  schema_definition do
    version 1
    name "CriterionAssessor"
    description "Assesses a criterion against matched evidence"
    field :assessment, :object, properties: {
      "new_status" => { type: "string", enum: %w[not_assessed met partially_met not_met no_longer_applicable] },
      "evidence_notes" => { type: "string", description: "Explanation referencing specific evidence" },
      "confidence" => { type: "number", description: "0.0 to 1.0" }
    }
  end

  def system_prompt
    "You are a government accountability analyst assessing specific criteria against available evidence."
  end

  def prompt(criterion, evidence_items)
    <<~PROMPT
    You are assessing a specific criterion for a government commitment based on available evidence.

    COMMITMENT:
    Title: #{criterion.commitment.title}
    Description: #{criterion.commitment.description}
    Type: #{criterion.commitment.commitment_type}

    CRITERION TO ASSESS:
    Category: #{criterion.category}
    Description: #{criterion.description}
    Verification Method: #{criterion.verification_method}
    Current Status: #{criterion.status}
    Previous Evidence: #{criterion.evidence_notes}

    MATCHED EVIDENCE:
    #{format_evidence(evidence_items)}

    ASSESSMENT RULES:
    - met: Clear evidence that this criterion is fully satisfied
    - partially_met: Some evidence of progress but not complete
    - not_met: Evidence exists but shows criterion is not satisfied, or contradictory evidence
    - not_assessed: Insufficient evidence to make any determination
    - no_longer_applicable: The commitment has been abandoned or the criterion is moot

    Be CONSERVATIVE. Only mark as "met" if evidence clearly supports it.
    If current status is already "met" and no contradictory evidence, keep it "met".
    Reference specific evidence items in your evidence_notes.
    PROMPT
  end

  private

  def format_evidence(items)
    items.map do |item|
      case item
      when Entry
        "ENTRY: #{item.title} (#{item.published_at&.to_date})\n#{item.parsed_markdown&.truncate(1000)}"
      when Bill
        "BILL: #{item.bill_number_formatted} - #{item.short_title}\nLatest: #{item.latest_activity} (#{item.latest_activity_at&.to_date})"
      when StatcanDataset
        "STATCAN: #{item.name}\nData: #{item.current_data&.first(3)&.to_json}"
      end
    end.join("\n\n---\n\n")
  end
end
