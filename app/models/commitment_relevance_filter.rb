class CommitmentRelevanceFilter < Chat
  include Structify::Model

  MODEL = "gemini-3.1-flash-lite-preview"

  after_create { with_model(MODEL, provider: :gemini, assume_exists: true) }

  schema_definition do
    version 1
    name "CommitmentRelevanceFilter"
    description "Determines which commitments a data item is relevant to"
    field :matches, :array,
      description: "Commitments this data item is relevant to. Empty array if none.",
      items: {
        type: "object", properties: {
          "commitment_id" => { type: "integer" },
          "relevance_score" => { type: "number", description: "0.0 to 1.0" },
          "relevance_reasoning" => { type: "string", description: "1-2 sentences max" }
        }
      }
  end

  def system_prompt
    "You are a government accountability analyst matching evidence to tracked government commitments."
  end

  def prompt_for_entry(commitments_batch, entry)
    <<~PROMPT
    Determine which government commitments this news/document relates to.

    COMMITMENTS:
    #{format_commitments(commitments_batch)}

    DOCUMENT:
    #{entry.format_for_llm}

    Return ONLY commitments that this document provides evidence for or against.
    Score 0.8-1.0 = directly about this commitment
    Score 0.5-0.7 = indirectly relevant (related policy area, department action)
    Do NOT match on vague thematic similarity. The document must contain specific information relevant to evaluating the commitment.
    PROMPT
  end

  def prompt_for_bill(commitments_batch, bill)
    <<~PROMPT
    Determine which government commitments this parliamentary bill relates to.

    COMMITMENTS:
    #{format_commitments(commitments_batch)}

    BILL:
    Bill Number: #{bill.bill_number_formatted}
    Short Title: #{bill.short_title}
    Long Title: #{bill.long_title}
    Latest Activity: #{bill.latest_activity}
    House Stages: 1R=#{bill.passed_house_first_reading_at&.to_date} 2R=#{bill.passed_house_second_reading_at&.to_date} 3R=#{bill.passed_house_third_reading_at&.to_date}
    Senate Stages: 1R=#{bill.passed_senate_first_reading_at&.to_date} 2R=#{bill.passed_senate_second_reading_at&.to_date} 3R=#{bill.passed_senate_third_reading_at&.to_date}
    Royal Assent: #{bill.received_royal_assent_at&.to_date}

    Return ONLY commitments that this bill directly implements or advances.
    PROMPT
  end

  def prompt_for_statcan(commitments_batch, dataset)
    <<~PROMPT
    Determine which government commitments this Statistics Canada dataset is relevant to.

    COMMITMENTS:
    #{format_commitments(commitments_batch)}

    DATASET:
    Name: #{dataset.name}
    URL: #{dataset.statcan_url}
    Last Synced: #{dataset.last_synced_at}
    Data Summary: #{dataset.current_data&.first(5)&.to_json}

    Return ONLY commitments whose success or progress criteria could be measured using this dataset.
    PROMPT
  end

  private

  def format_commitments(batch)
    batch.map { |c| "ID #{c.id}: [#{c.commitment_type}] #{c.title} — #{c.description.truncate(150)}" }.join("\n")
  end
end
