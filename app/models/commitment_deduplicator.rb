class CommitmentDeduplicator < Chat
  include Structify::Model

  MODEL = "gemini-3.1-flash-lite-preview"

  after_create { with_model(MODEL, provider: :gemini, assume_exists: true) }

  schema_definition do
    version 1
    name "CommitmentDeduplicator"
    field :duplicate_pairs, :array,
      description: "Pairs of commitments that refer to the same promise",
      items: {
        type: "object", properties: {
          "keep_title" => { type: "string", description: "Title of the commitment to keep (prefer the more detailed one)" },
          "remove_title" => { type: "string", description: "Title of the duplicate commitment to remove" }
        }
      }
  end

  def system_prompt
    "You are a deduplication assistant that identifies duplicate government commitments extracted from overlapping document pages."
  end

  def prompt(chunk_a_commitments, chunk_b_commitments)
    <<~PROMPT
    Two adjacent chunks of a document were processed with a 1-page overlap.
    Some commitments may have been extracted from both chunks with slightly different wording.

    Identify any DUPLICATE pairs — commitments that refer to the same promise.
    Two commitments are duplicates if they describe the same specific action, even if the titles differ slightly.
    Only flag true duplicates, not merely related commitments.

    For each duplicate pair, pick the one with the more specific/detailed title to keep.

    CHUNK A commitments:
    #{format_commitments(chunk_a_commitments)}

    CHUNK B commitments:
    #{format_commitments(chunk_b_commitments)}
    PROMPT
  end

  private

  def format_commitments(commitments)
    commitments.map do |c|
      "- #{c['title']}\n  Description: #{c['description']&.truncate(200)}"
    end.join("\n")
  end
end
