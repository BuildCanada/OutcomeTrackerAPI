class CommitmentStatusDeriver < Chat
  include Structify::Model

  MODEL = "gemini-3.1-flash-lite-preview"

  after_create { with_model(MODEL, provider: :gemini, assume_exists: true) }

  schema_definition do
    version 1
    name "CommitmentStatusDeriver"
    description "Derives overall commitment status from criteria assessments"
    field :derivation, :object, properties: {
      "recommended_status" => { type: "string", enum: %w[not_started in_progress completed abandoned] },
      "reasoning" => { type: "string", description: "Explanation of why this status was recommended" },
      "confidence" => { type: "number", description: "0.0 to 1.0" }
    }
  end

  def system_prompt
    "You are a government accountability analyst determining the overall status of a commitment based on its evaluation criteria."
  end

  def prompt(commitment)
    criteria_summary = commitment.criteria.where.not(category: :success).map do |c|
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

    MATCHED EVIDENCE SUMMARY:
    #{format_evidence_summary(commitment)}

    CRITERIA AND THEIR CURRENT ASSESSMENTS:
    #{criteria_summary.presence || "(No criteria assessed yet)"}

    STATUS DEFINITIONS:
    - not_started: No evidence of any action taken on this commitment
    - in_progress: Some action has been taken but the commitment is not yet fulfilled
    - completed: The government has done what it said it would do — completion criteria are met
    - abandoned: The government has explicitly reversed or dropped this commitment

    EVIDENCE HIERARCHY (strictly enforced):
    For "completed" status, one of these is REQUIRED:
    - Legislative commitments: A matched bill with Royal Assent, OR a Gazette Part III entry
    - Regulatory commitments: A matched Gazette Part II entry (enacted regulation)
    - Spending/program commitments: Departmental news showing the program is operational

    For "in_progress" status, one of these is REQUIRED:
    - A matched bill that has been introduced and is progressing (but no Royal Assent yet)
    - A Gazette Part I entry (proposed regulation)
    - Appropriation voted (matched to appropriation bill) with program evidence
    - Departmental news showing concrete implementation steps

    Budget announcements alone (Budget 2025 text, budget speeches) are NOT sufficient evidence
    for "in_progress" or "completed". A budget promise without a bill, regulation, or program
    launch is "not_started".

    RULES:
    - If completion criteria are met AND strong evidence exists per the hierarchy, recommend "completed".
    - Progress criteria being met with appropriate evidence suggests "in_progress".
    - If criteria are mostly "not_assessed", keep status as "not_started" unless there's clear evidence of action.
    - If the only evidence is budget text or platform promises, recommend "not_started".
    - Never recommend "abandoned" unless there is explicit evidence of reversal.
    PROMPT
  end

  private

  def format_evidence_summary(commitment)
    matches = commitment.commitment_matches.includes(:matchable)
    return "(No matched evidence)" if matches.empty?

    summary_parts = []

    bill_matches = matches.select { |m| m.matchable_type == "Bill" }
    if bill_matches.any?
      bill_matches.each do |m|
        bill = m.matchable
        next unless bill

        royal_assent = bill.received_royal_assent_at.present? ? "Royal Assent #{bill.received_royal_assent_at.to_date}" : "No Royal Assent"
        house_stage = if bill.passed_house_third_reading_at
          "Passed House 3R"
        elsif bill.passed_house_second_reading_at
          "Passed House 2R"
        elsif bill.passed_house_first_reading_at
          "Passed House 1R"
        else
          "Introduced"
        end
        summary_parts << "BILL: #{bill.bill_number_formatted} — #{bill.short_title} (#{house_stage}, #{royal_assent})"
      end
    end

    entry_matches = matches.select { |m| m.matchable_type == "Entry" }
    if entry_matches.any?
      entry_matches.group_by { |m| m.matchable&.feed }.each do |feed, feed_matches|
        next unless feed

        summary_parts << "#{feed.title}: #{feed_matches.size} matched entries"
      end
    end

    statcan_matches = matches.select { |m| m.matchable_type == "StatcanDataset" }
    if statcan_matches.any?
      summary_parts << "StatCan datasets: #{statcan_matches.size} matched"
    end

    summary_parts.presence&.join("\n") || "(No matched evidence)"
  end
end
