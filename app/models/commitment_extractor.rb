class CommitmentExtractor < Chat
  include Structify::Model

  MODEL = "gemini-3.1-pro-preview"

  after_create { with_model(MODEL, provider: :gemini, assume_exists: true) }

  schema_definition do
    version 1
    name "CommitmentExtractor"
    field :commitments, :array,
      items: {
        type: "object", properties: {
          "title" => { type: "string", description: "Specific, action-oriented title. Not a copy of the original text." },
          "description" => { type: "string", description: "Precise description of what was promised. Must add analytical value beyond original_text." },
          "original_text" => { type: "string", description: "Verbatim text from the document" },
          "commitment_type" => { type: "string", enum: %w[legislative spending procedural institutional diplomatic outcome aspirational] },
          "policy_area_slug" => { type: "string" },
          "department_slugs" => { type: "array", items: { type: "object", properties: {
            "slug" => { type: "string" }, "is_lead" => { type: "boolean" }
          } } },
          "parent_title" => { type: "string", description: "Title of parent commitment if this is a child. null for top-level." },
          "source_section" => { type: "string" },
          "source_reference" => { type: "string", description: "Page reference, e.g. 'p. 42'" },
          "existing_commitment_id" => { type: "integer", description: "ID of existing commitment this updates/matches. null if new." }
        }
      }
  end

  def system_prompt
    "You are a government policy analyst specializing in extracting structured commitments from policy documents."
  end

  def prompt(chunk, existing_commitments, policy_areas, departments)
    <<~PROMPT
    You are extracting government commitments from a policy document section.

    STRUCTURING RULES:
    1. ONE verifiable thing per commitment. Compound promises -> parent + children.
    2. Title must be specific and action-oriented: "Increase defence spending to 2% of GDP by 2030" NOT "Strengthen defence"
    3. Description must ADD ANALYTICAL VALUE beyond the original text. Clarify the mechanism, target, or timeline.
    4. If a section has 3+ related commitments, create a parent commitment (type: aspirational) that groups them.
    5. Always preserve the verbatim original_text.
    6. Check existing commitments for duplicates - if this commitment already exists, set existing_commitment_id.

    CLASSIFICATION RULES:
    - spending: Explicit dollar amounts, funding, tax cuts, investment programs
    - legislative: Bills, amendments, Criminal Code changes, new Acts
    - procedural: Process changes, reviews, strategy launches, agency mandates
    - institutional: New agencies, offices, boards
    - outcome: Measurable targets with specific numbers
    - diplomatic: International agreements, treaties, alliances
    - aspirational: Broad directional goals without specific metrics (also use for parent groupings)

    AVAILABLE POLICY AREAS:
    #{policy_areas.map { |pa| "#{pa.slug}: #{pa.name}" }.join("\n")}

    AVAILABLE DEPARTMENTS:
    #{departments.map { |d| "#{d.slug}: #{d.display_name}" }.join("\n")}

    EXISTING COMMITMENTS (check for duplicates):
    #{existing_commitments.map { |c| "ID #{c.id}: #{c.title}" }.join("\n")}

    DOCUMENT SECTION:
    Section: #{chunk["section_title"]}
    Pages: #{chunk["page_range"]}
    Content:
    #{chunk["content"]}
    PROMPT
  end
end
