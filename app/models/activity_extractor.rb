class ActivityExtractor < Chat
  include Structify::Model

  def prompt(promises, entry)
    <<~PROMPT
    You are tasked with extracting activities from political artifacts that could impact the progress of promises made by the government. This analysis will help track the government's actions and their potential effects on fulfilling their commitments.

    First, review the list of government promises:
    <government_promises>
    #{promises.map(&:format_for_llm).join("\n")}
    </government_promises>

    Now, carefully read and analyze the following political artifact:
    #{entry.format_for_llm}

    Your task is to extract activities mentioned in the political artifact that could potentially impact the progress of the government promises listed above. Follow these steps:

    1. Identify any actions, initiatives, policies, or decisions mentioned in the artifact.
    2. For each identified activity, determine if it relates to any of the government promises.
    3. Assess whether the activity could have a positive, negative, or neutral impact on the progress of the related promise(s).

    When analyzing the impact:
    - Consider direct and indirect effects. If the promise is specific, do not consider indirect effects.
    - Think about short-term and long-term consequences
    - Take into account the scale and scope of the activity

    Present your findings as JSON.

    If no relevant activities are found in the political artifact, state this clearly in your response.

    Try to minimize the number of activities listed, they should be combined if they are similar enough to avoid redundancy.

    Remember to focus only on activities that could potentially impact the government's progress on their promises. Do not include unrelated information or speculate beyond what is reasonably implied by the artifact.
    PROMPT
  end

  schema_definition do
    version 1
    name "ActivityExtraction"
    description "Extracts activities from an entry"
    field :reason_for_no_activities, :string, description: "Reason for the activity extraction"
    field :activities, :array,
      description: "List of activities that the government has impacted one of the promises",
      items: {
        type: "object", properties: {
      "title" => { type: "string" },
      "summary" => { type: "string", description: "Summary of what the government has done or proposed to do" },
      "impacted_promises" => { type: "array", items: { type: "object", properties: {
        "promise_id" => { type: "string", description: "The ID of the promise that the activity impacts" },
        "potential_impact" => { type: "string", enum: [ "positive", "negative", "neutral" ] },
        "potential_impact_magnitude" => { type: "integer", description: "The magnitude of the potential impact on the promise(s). 1 indicates a minor impact, 2 indicates a moderate impact, and 3 indicates a significant impact." },
        "potential_impact_reason" => { type: "string", description: "Explain the potential impact on the promise(s), whether positive, negative, or neutral, and why" }
      } } }
    }
      }
  end

  def extract_activities!
    raise ArgumentError.new("Record is not provided") unless self.record and self.record.is_a?(Entry)
    p = prompt(
      Promise.all,
      self.record
    )

    self.extract! p

    activities.each do |activity|
      if activity["impacted_promises"].blank?
        Rails.logger.info("No impacted promises found for activity: #{activity["title"]}, extractor_id: #{self.id}")
        next
      end

      rec = Activity.create!(
        government_id: self.record.government_id,
        entry: self.record,
        title: activity["title"],
        summary: activity["summary"],
        published_at: self.record.published_at
      )

      activity["impacted_promises"].each do |impacted_promise|
        rec.evidences.create!(
          promise_id: Promise.find_by!(promise_id: impacted_promise["promise_id"]).id,
          linked_at: Time.now,
          link_type: "automated",
          impact: impacted_promise["potential_impact"],
          impact_magnitude: impacted_promise["potential_impact_magnitude"],
          impact_reason: impacted_promise["potential_impact_reason"]
        )
      end
    end
  end
end
