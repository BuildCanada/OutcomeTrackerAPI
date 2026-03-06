class DocumentChunker < Chat
  include Structify::Model

  MODEL = "gemini-3.1-flash-lite-preview"

  after_create { with_model(MODEL, provider: :gemini, assume_exists: true) }

  schema_definition do
    version 1
    name "DocumentChunker"
    field :chunks, :array,
      description: "Logical sections of the document, each containing related commitments",
      items: {
        type: "object", properties: {
          "section_title" => { type: "string", description: "Section heading (e.g. 'UNITE - One Canadian Economy')" },
          "content" => { type: "string", description: "Full text of the section" },
          "page_range" => { type: "string", description: "Page range, e.g. '12-15'" }
        }
      }
  end

  def system_prompt
    "You are a document processing assistant that splits government policy documents into logical sections."
  end

  def prompt(pdf_text)
    <<~PROMPT
    You are processing a government policy document. Split it into logical sections
    that each contain a coherent set of commitments/promises.

    Rules:
    - Each chunk should be a self-contained section (e.g., a chapter or major topic area)
    - Preserve ALL text - do not summarize or truncate
    - Include section headers/titles from the document
    - Each chunk should be small enough to analyze individually (max ~3000 words)
    - Track page numbers from the [PAGE X] markers in the text

    Document text:
    #{pdf_text}
    PROMPT
  end
end
