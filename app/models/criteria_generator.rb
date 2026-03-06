class CriteriaGenerator < Chat
  include Structify::Model

  schema_definition do
    version 1
    name "CriteriaGenerator"
    description "Generates assessment criteria for a commitment"
    field :criteria, :array,
      description: "Assessment criteria across four categories",
      items: {
        type: "object", properties: {
          "category" => { type: "string", enum: %w[completion success progress failure],
            description: "completion = did they literally do it (the letter), success = did the real-world outcome materialize as intended (the spirit), progress = are they working towards it, failure = evidence the commitment is broken or contradicted" },
          "description" => { type: "string",
            description: "Specific, measurable criterion. Include quantitative targets where possible." },
          "verification_method" => { type: "string",
            description: "Specific data source or method to check. Must name actual sources (LEGISinfo, Budget docs, StatCan table, etc.)" },
          "position" => { type: "integer", description: "Display order within category (0-indexed)" }
        }
      }
  end

  def prompt(commitment)
    <<~PROMPT
    You are a government accountability analyst generating assessment criteria for a Canadian federal government commitment.

    COMMITMENT:
    Title: #{commitment.title}
    Description: #{commitment.description}
    Original Text: #{commitment.original_text}
    Type: #{commitment.commitment_type}
    Policy Area: #{commitment.policy_area&.name}
    Lead Department: #{commitment.lead_department&.display_name}
    All Departments: #{commitment.departments.map(&:display_name).join(', ')}

    GENERATE CRITERIA following these rules:

    COMPLETION CRITERIA (2-4) — "Did they literally do what they said?"
    - The letter of the commitment: did the government take the specific action promised?
    - Include QUANTITATIVE targets where the commitment states them
    - For spending: was the dollar amount actually allocated and disbursed?
    - For legislative: did the bill receive Royal Assent?
    - For outcome: was the specific target met on paper?
    - Each criterion must be independently verifiable

    SUCCESS CRITERIA (2-3) — "Did the real-world outcome materialize as intended?"
    - The spirit of the commitment: after doing it on paper, did the intended effect actually happen?
    - Go beyond the letter to assess whether the action achieved its purpose
    - Examples: legislation passed, but did it actually reduce trade barriers? Funding allocated, but did the program deliver results?
    - Focus on measurable real-world impact, not just government process

    PROGRESS CRITERIA (1-2) — "Are they actively working towards it?"
    - Evidence that the government is taking steps toward fulfillment
    - Useful for tracking commitments that are not yet complete
    - Examples: bill introduced and moving through Parliament, consultations launched, budget line item created
    - Should reference specific data sources (LEGISinfo, departmental reports, etc.)

    FAILURE CRITERIA (1-2) — "Is the commitment broken or actively contradicted?"
    - Red flags that indicate the commitment has been abandoned, reversed, or undermined
    - These should trigger immediately if met — not "hasn't happened yet" but "something happened that breaks it"
    - Examples: government introduces legislation that contradicts the commitment, budget cuts the relevant program, official statement walks back the promise, policy reversal announced
    - For spending: funds redirected or program cancelled
    - For legislative: competing bill introduced that undermines intent, government votes against its own commitment
    - For outcome: indicator moving in the wrong direction due to government action
    - Should be specific and falsifiable — not vague concerns

    VERIFICATION METHOD RULES:
    - MUST name a specific data source, not "Monitor government announcements"
    - Good: "LEGISinfo bill tracking for C-XX", "Federal Budget Chapter 3", "StatCan Table 36-10-0222-01"
    - Good: "DND Departmental Results Report", "Main Estimates Part II", "Canada Gazette Part II"
    - Bad: "Review government reports", "Check media coverage", "Monitor progress"

    TYPE-SPECIFIC GUIDANCE:
    #{type_guidance(commitment.commitment_type)}

    Return criteria as a JSON array.
    PROMPT
  end

  def generate_criteria!
    raise ArgumentError, "Record must be a Commitment" unless record.is_a?(Commitment)

    extract!(prompt(record))

    record.criteria.where(status: :not_assessed).destroy_all

    criteria.each do |criterion_data|
      Criterion.create!(
        commitment: record,
        category: criterion_data["category"],
        description: criterion_data["description"],
        verification_method: criterion_data["verification_method"],
        status: :not_assessed,
        position: criterion_data["position"] || 0
      )
    end

    record.update!(criteria_generated_at: Time.current)
  end

  private

  def type_guidance(commitment_type)
    case commitment_type
    when "legislative"
      <<~GUIDE
      - Completion (the letter): Bill receives Royal Assent, regulations published in Canada Gazette
      - Success (the spirit): Did the law actually achieve its intended policy outcome? Are the regulations effective in practice?
      - Progress (working towards it): Bill introduced, moving through readings, committee study underway
      - Failure (broken): Government votes against the bill, withdraws it, or introduces competing legislation that contradicts the commitment
      - Verification: LEGISinfo, Canada Gazette Part II, Hansard, departmental evaluations
      GUIDE
    when "spending"
      <<~GUIDE
      - Completion (the letter): Full funding amount allocated AND disbursed as promised
      - Success (the spirit): Did the spending achieve the intended outcome? Did the program deliver results to the target population?
      - Progress (working towards it): Budget line item created, Main Estimates allocation, program accepting applications
      - Failure (broken): Funding cut, program cancelled, budget reallocates funds away from the commitment
      - Verification: Federal Budget, Main Estimates, Supplementary Estimates, Public Accounts, Departmental Results Reports
      GUIDE
    when "procedural"
      <<~GUIDE
      - Completion (the letter): New process/review completed and formally implemented
      - Success (the spirit): Did the new process actually improve outcomes? Is it functioning as intended?
      - Progress (working towards it): Review launched, consultations underway, interim report published
      - Failure (broken): Review cancelled, directive reversed, or new directive issued that contradicts the original commitment
      - Verification: Canada Gazette, Order in Council database, departmental websites, evaluation reports
      GUIDE
    when "institutional"
      <<~GUIDE
      - Completion (the letter): Organization formally created via legislation or order
      - Success (the spirit): Is the organization staffed, operational, and fulfilling its mandate effectively?
      - Progress (working towards it): Enabling legislation tabled, appointments in process, budget allocated
      - Failure (broken): Organization dissolved, defunded, or mandate changed to contradict original purpose
      - Verification: GIC appointments, Canada Gazette, departmental org charts, annual reports
      GUIDE
    when "diplomatic"
      <<~GUIDE
      - Completion (the letter): Agreement signed/ratified, formal obligations entered into
      - Success (the spirit): Are the agreement's intended benefits materializing? Are obligations being met by all parties?
      - Progress (working towards it): Negotiations initiated, framework discussions underway, domestic enabling legislation tabled
      - Failure (broken): Withdrawal from negotiations, refusal to ratify, or actions that violate agreement terms
      - Verification: GAC treaty database, joint statements, UN/NATO communiques, trade statistics
      GUIDE
    when "outcome"
      <<~GUIDE
      - Completion (the letter): Government took the specific actions it committed to (programs launched, targets set)
      - Success (the spirit): Did the measurable indicator actually reach the target value? Is the real-world outcome achieved?
      - Progress (working towards it): Programs operational, indicator trending toward target
      - Failure (broken): Indicator moving in the wrong direction due to government action/inaction, or program cancelled
      - Verification: StatCan indicators, departmental results reports, third-party reports
      GUIDE
    when "aspirational"
      <<~GUIDE
      - Completion (the letter): Government launched concrete programs or policies in the stated direction
      - Success (the spirit): Are directional indicators actually showing improvement? Is real-world change evident?
      - Progress (working towards it): Policy development underway, early programs launched, stakeholder engagement active
      - Failure (broken): Government adopts policies that actively move in the opposite direction, or abandons the stated aspiration
      - Verification: StatCan, departmental reports, international rankings
      GUIDE
    end
  end
end
