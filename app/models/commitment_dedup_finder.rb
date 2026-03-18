class CommitmentDedupFinder < Chat
  include Structify::Model

  MODEL = "gemini-3.1-flash-lite-preview"

  after_create { with_model(MODEL, provider: :gemini, assume_exists: true) }

  schema_definition do
    version 1
    name "CommitmentDedupFinder"
    description "Identifies duplicate commitments across the full set"
    field :duplicate_groups, :array,
      description: "Groups of commitments that refer to the same promise",
      items: {
        type: "object", properties: {
          "keep_id" => { type: "integer", description: "ID of the most detailed/complete commitment to keep" },
          "merge_ids" => { type: "array", items: { type: "integer" }, description: "IDs of duplicates to merge into the kept commitment" },
          "reason" => { type: "string", description: "Why these are duplicates" }
        }
      }
  end

  def system_prompt
    "You are a deduplication analyst identifying duplicate government commitments. " \
    "Two commitments are duplicates if they refer to the same specific promise, even if worded differently. " \
    "Related but distinct commitments are NOT duplicates."
  end

  def prompt(commitments)
    <<~PROMPT
    Review the following government commitments and identify any DUPLICATE groups.
    Duplicates are commitments that refer to the SAME specific promise, even if worded differently.

    Related but distinct commitments are NOT duplicates. Be conservative — only flag true duplicates.

    For each group, pick the most detailed/complete version to keep.

    COMMITMENTS:
    #{commitments.map { |c| "ID #{c.id}: [#{c.commitment_type}] #{c.title}\n  Description: #{c.description}" }.join("\n\n")}
    PROMPT
  end
end
