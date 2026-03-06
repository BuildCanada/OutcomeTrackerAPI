class SourceDocumentProcessorJob < ApplicationJob
  queue_as :default

  def perform(source_document)
    source_document.update!(status: :processing)

    pages = extract_pdf_pages(source_document.document)
    chunks = chunk_pages(pages)

    existing_commitments = Commitment.where(government: source_document.government)
    policy_areas = PolicyArea.all
    departments = Department.where(government: source_document.government)
    all_extracted = []

    completed_extractors = CommitmentExtractor.where(record: source_document)
                                               .order(:created_at)
                                               .select { |e| e.commitments.present? }

    chunks.each_with_index do |chunk, i|
      extractor = completed_extractors[i]

      if extractor
        Rails.logger.info("Reusing existing extraction for #{chunk['section_title']}")
      else
        extractor = CommitmentExtractor.create!(record: source_document)
        extractor.extract!(extractor.prompt(chunk, existing_commitments, policy_areas, departments))
      end

      all_extracted.concat(extractor.commitments.map { |c| c.merge("chunk_section" => chunk["section_title"]) })
    end

    deduped = deduplicate(all_extracted, source_document)

    source = create_source(source_document)
    created_commitments = create_commitments(deduped, source_document.government, source, policy_areas, departments)

    set_parent_relationships(created_commitments, deduped)

    source_document.update!(
      status: :extracted,
      extraction_metadata: { commitment_count: created_commitments.size, chunk_count: chunks.size }
    )
  rescue => e
    source_document.update!(status: :failed, error_message: e.message)
    raise
  end

  private

  def extract_pdf_pages(attachment)
    attachment.open do |file|
      reader = PDF::Reader.new(file.path)
      reader.pages.map.with_index(1) do |page, i|
        "[PAGE #{i}]\n#{page.text}"
      end
    end
  end

  def chunk_pages(pages, per_chunk: 10)
    return [build_chunk(pages, 1, pages.size)] if pages.size <= per_chunk

    chunks = []
    start_idx = 0

    while start_idx < pages.size
      end_idx = [start_idx + per_chunk, pages.size].min
      chunks << build_chunk(pages[start_idx...end_idx], start_idx + 1, end_idx)
      break if end_idx >= pages.size
      start_idx = end_idx - 1 # 1-page overlap
    end

    chunks
  end

  def build_chunk(page_texts, first_page, last_page)
    {
      "section_title" => "Pages #{first_page}-#{last_page}",
      "page_range" => "#{first_page}-#{last_page}",
      "content" => page_texts.join("\n\n")
    }
  end

  def deduplicate(commitments, source_document)
    # Group by chunk section
    by_chunk = commitments.group_by { |c| c["chunk_section"] }
    chunk_keys = by_chunk.keys

    # Use LLM to find duplicates between adjacent chunks
    titles_to_remove = Set.new

    chunk_keys.each_cons(2) do |chunk_a_key, chunk_b_key|
      chunk_a_titles = by_chunk[chunk_a_key].map { |c| c["title"] }
      chunk_b_titles = by_chunk[chunk_b_key].map { |c| c["title"] }

      deduper = CommitmentDeduplicator.create!(record: source_document)
      deduper.extract!(deduper.prompt(chunk_a_titles, chunk_b_titles))

      (deduper.duplicate_pairs || []).each do |pair|
        titles_to_remove << pair["remove_title"]
      end
    end

    commitments.reject { |c| titles_to_remove.include?(c["title"]) }
  end

  def create_source(source_document)
    Source.create!(
      government: source_document.government,
      source_document: source_document,
      title: source_document.title,
      source_type: source_document.source_type,
      url: source_document.url,
      date: source_document.date
    )
  end

  def create_commitments(extracted, government, source, policy_areas, departments)
    pa_lookup = policy_areas.index_by(&:slug)
    dept_lookup = departments.index_by(&:slug)
    created = {}

    extracted.each do |data|
      next if data["title"].blank? || data["description"].blank? || data["commitment_type"].blank?

      if data["existing_commitment_id"].to_i > 0 && (commitment = Commitment.find_by(id: data["existing_commitment_id"]))
        CommitmentSource.find_or_create_by!(commitment: commitment, source: source) do |cs|
          cs.section = data["source_section"]
          cs.reference = data["source_reference"]
          cs.excerpt = data["original_text"]&.truncate(500)
        end
        created[data["title"]] = commitment
        next
      end

      commitment = Commitment.create!(
        government: government,
        title: data["title"],
        description: data["description"],
        original_text: data["original_text"],
        commitment_type: data["commitment_type"],
        status: :not_started,
        policy_area: pa_lookup[data["policy_area_slug"]],
        party_code: "LPC",
        region_code: "federal",
        date_promised: source.date
      )

      CommitmentSource.create!(
        commitment: commitment,
        source: source,
        section: data["source_section"],
        reference: data["source_reference"],
        excerpt: data["original_text"]&.truncate(500)
      )

      (data["department_slugs"] || []).each do |dept_data|
        dept = dept_lookup[dept_data["slug"]]
        next unless dept
        CommitmentDepartment.find_or_create_by!(commitment: commitment, department: dept) do |cd|
          cd.is_lead = dept_data["is_lead"] || false
        end
      end

      created[data["title"]] = commitment
    end

    created
  end

  def set_parent_relationships(created, extracted)
    extracted.each do |data|
      next unless data["parent_title"].present?
      child = created[data["title"]]
      parent = created[data["parent_title"]]
      next unless child && parent
      child.update!(parent: parent) unless child.parent_id == parent.id
    end
  end
end
