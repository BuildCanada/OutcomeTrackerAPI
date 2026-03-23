class CriterionAssessor < Chat
  include Structify::Model

  MODEL = "gemini-3.1-pro-preview"

  after_create { with_model(MODEL, provider: :gemini, assume_exists: true) }

  schema_definition do
    version 1
    name "CriterionAssessor"
    description "Assesses a criterion against matched evidence"
    field :assessment, :object, properties: {
      "new_status" => { type: "string", enum: %w[not_assessed met not_met no_longer_applicable] },
      "evidence_notes" => { type: "string", description: "Explanation referencing specific evidence" },
      "confidence" => { type: "number", description: "0.0 to 1.0" },
      "primary_evidence_index" => { type: "integer", description: "0-based index of the most relevant evidence item used for this assessment, from the MATCHED EVIDENCE list" }
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
    - not_met: Criterion is not satisfied, even if there is some progress toward it
    - not_assessed: Insufficient evidence to make any determination
    - no_longer_applicable: The commitment has been abandoned or the criterion is moot

    There is NO "partially met" status. Criteria are binary: met or not_met.
    Progress toward meeting a criterion does not make it met — that is tracked separately by progress criteria.

    EVIDENCE STANDARDS (critical):
    - Budget announcements, budget speeches, and platform promises are NOT evidence of action.
      They are statements of intent. A budget saying "we will do X" does not mean X is done or in progress.
    - For COMPLETION criteria: require Royal Assent (for legislation), Gazette Part II publication
      (for regulations), or operational program evidence (for spending/programs).
    - For PROGRESS criteria: require a bill progressing through Parliament, a Gazette Part I
      proposed regulation, or departmental news showing concrete implementation steps.
    - A bill that has NOT received Royal Assent means the legislation is NOT enacted.
      The Budget Implementation Act (Bill C-15) being introduced or progressing is evidence of
      progress, NOT completion.

    Be CONSERVATIVE. Only mark as "met" if evidence clearly supports it.
    If current status is already "met" and no contradictory evidence, keep it "met".
    Reference specific evidence items in your evidence_notes.
    Set primary_evidence_index to the 0-based index of the evidence item that most directly supports your assessment.
    PROMPT
  end

  private

  def format_evidence(items)
    items.each_with_index.map do |item, idx|
      case item
      when Entry
        "[#{idx}] ENTRY [#{item.feed&.title}]: #{item.title} (#{item.published_at&.to_date})\n#{item.parsed_markdown&.truncate(1000)}"
      when Bill
        royal_assent = item.received_royal_assent_at.present? ? "ENACTED (Royal Assent #{item.received_royal_assent_at.to_date})" : "NOT ENACTED"
        "[#{idx}] BILL: #{item.bill_number_formatted} - #{item.short_title}\nStatus: #{royal_assent}\nLatest: #{item.latest_activity} (#{item.latest_activity_at&.to_date})\nHouse: 1R=#{item.passed_house_first_reading_at&.to_date} 2R=#{item.passed_house_second_reading_at&.to_date} 3R=#{item.passed_house_third_reading_at&.to_date}\nSenate: 1R=#{item.passed_senate_first_reading_at&.to_date} 2R=#{item.passed_senate_second_reading_at&.to_date} 3R=#{item.passed_senate_third_reading_at&.to_date}"
      when StatcanDataset
        "[#{idx}] STATCAN: #{item.name}\nData: #{item.current_data&.first(3)&.to_json}"
      end
    end.join("\n\n---\n\n")
  end
end
