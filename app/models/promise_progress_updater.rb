class PromiseProgressUpdater < Chat
    include Structify::Model

    def prompt(promise)
      <<~PROMPT
      You are a specialized government accountability analyst. Your task is to assess the progress made on specific government commitments based on available evidence of government actions.

      **Your Mission:**
      Analyze the provided government commitment and associated evidence to determine how much progress has been made toward fulfilling that commitment. You will assign a progress score and provide a factual summary based solely on the evidence provided.

      **Input Data Structure:**
      You will receive:
      1. **Promise Information:**
        - `promise_id`: The internal ID for the promise
        - `title`:#{' '}
        - `description`:
        - `text`:#{' '}
        - `responsible_department_lead`: The department responsible for this commitment
        - `intended_impact_and_objectives`: What the commitment aims to achieve
        - `background_and_context`: Additional context about the commitment

      2. **Evidence Items:** A list of government actions/evidence related to this commitment, each containing:
        - `title_or_summary`: Brief description of the government action
        - `evidence_source_type`: Type of evidence (e.g., "Bill Event (LEGISinfo)", "Canada Gazette Part II", "OIC", "News")
        - `evidence_date`: When this action occurred (YYYY-MM-DD format)
        - `description_or_details`: Detailed description of the action
        - `source_url`: Official government source URL
        - `bill_one_sentence_description_llm`: (For bills only) AI-generated description of the bill's purpose

      First, carefully read and analyze the following promise information:
      <promise>
      #{promise.format_for_llm}
      </promise>

      Now, review the list of evidence items:

      <evidence_items>
      #{promise.evidences.map(&:format_for_llm).join("\n")}
      </evidence_items>

      **Progress Scoring Scale (1-5):**

      **Score 1 - No Progress:**
      - No meaningful government action found
      - No relevant legislation introduced
      - No funding allocated or programs launched

      **Score 2 - Initial Steps:**
      - Early-stage actions like consultations launched
      - Preliminary announcements or studies initiated
      - Minor policy discussions or planning activities
      - No significant legislative action or substantial funding

      **Score 3 - Meaningful Action:**
      - Legislation introduced and progressing through Parliament
      - Significant budget allocation announced or programs launched
      - Substantial policy development or regulatory work initiated
      - Clear government commitment with concrete steps taken

      **Score 4 - Major Progress:**
      - Key legislation passed major parliamentary stages (e.g., passed one House)
      - Substantial regulatory changes enacted or published
      - Significant funding disbursed and programs operational
      - Major implementation milestones achieved

      **Score 5 - Complete/Fully Implemented:**
      - All necessary legislation received Royal Assent and in force
      - Key regulations published and operational
      - All announced funding allocated and programs fully operational
      - Commitment objectives substantially achieved

      **Analysis Guidelines:**
      1. **Evidence-Based Assessment:** Base your score only on the provided evidence
      2. **Legislative Tracking:** Consider all stages of bill progress (introduction, readings, committee, Royal Assent)
      3. **Implementation Focus:** Distinguish between announcements and actual implementation
      4. **Proportional Scoring:** Consider the scope and complexity of the commitment
      5. **Temporal Relevance:** Focus on actions within the current parliamentary session

      **Output Format:**
      Provide your assessment as a JSON object with this exact structure:

      ```json
      {
        "progress_score": 3,
        "progress_summary": "A concise, factual summary (max 150 words) describing the key actions taken and current status based on the evidence provided. Focus on concrete actions, legislative milestones, funding allocations, and implementation status."
      }
      ```

      **Key Requirements:**
      - **Objectivity:** Base assessments only on provided evidence, avoid speculation
      - **Clarity:** Use clear, factual language in the progress summary
      - **Completeness:** Consider all evidence items when determining the score
      - **Accuracy:** Ensure the score aligns with the evidence and scoring criteria
      - **Conciseness:** Keep the summary focused and under 150 words

      **Example Scoring Logic:**
      - If a bill was introduced but hasn't progressed → Score 2-3
      - If a bill passed one House of Parliament → Score 3-4#{'  '}
      - If a bill received Royal Assent → Score 4-5
      - If funding was announced but not yet disbursed → Score 2-3
      - If programs are operational with funding flowing → Score 4-5
      - If no relevant evidence found → Score 1#{' '}
      PROMPT
    end


  schema_definition do
    version 1
    name "PromiseProgressUpdater"
    description "Updates the progress of a promise"
    field :promise_summary, :object, properties: {
        "progress_score" => { type: "integer" },
        "progress_summary" => { type: "string", description: "Summary of the progress the government has made towards a promise" }
      }
  end


  def update_promise_progress!
    raise ArgumentError.new("Promise is not provided") unless self.record and self.record.is_a?(Promise)

    p = prompt(
      self.record
    )

    self.extract! p

    self.record.progress_score = promise_summary["progress_score"]
    self.record.progress_summary = promise_summary["progress_summary"]
    self.record.save!
  end
end
