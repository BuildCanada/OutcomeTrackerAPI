class TargetDateExtractor < Chat
  include Structify::Model

  MODEL = "gemini-3.1-flash-lite-preview"

  after_create { with_model(MODEL, provider: :gemini, assume_exists: true) }

  schema_definition do
    version 1
    name "TargetDateExtractor"
    description "Extracts explicit target dates from commitment text"
    field :extraction, :object, properties: {
      "target_date" => { type: "string", description: "ISO 8601 date (YYYY-MM-DD) or null if no explicit deadline" },
      "reasoning" => { type: "string", description: "Explanation of how the date was derived or why none was found" }
    }
  end

  def system_prompt
    "You are a government policy analyst extracting explicit deadlines from commitment text. " \
    "Only extract dates that are EXPLICITLY stated in the text. Never infer or assign default dates."
  end

  def prompt(commitment)
    <<~PROMPT
    Extract the target date from this government commitment, if one is explicitly mentioned.

    COMMITMENT:
    Title: #{commitment.title}
    Description: #{commitment.description}
    Original Text: #{commitment.original_text}
    Date Promised: #{commitment.date_promised}

    RULES:
    - Only extract dates that are EXPLICITLY mentioned in the text
    - Parse relative deadlines relative to the date_promised:
      - "within 60 days" -> date_promised + 60 days
      - "by Canada Day" -> July 1 of the relevant year
      - "within six months" -> date_promised + 6 months
    - Parse absolute deadlines directly:
      - "by 2029" -> 2029-12-31
      - "before 2030" -> 2029-12-31
      - "by end of 2026" -> 2026-12-31
    - If there is NO explicit deadline in the text, return null for target_date
    - Do NOT assign default dates or infer timelines
    PROMPT
  end
end
