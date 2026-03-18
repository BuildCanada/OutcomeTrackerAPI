class SourceDocumentProcessorJob < ApplicationJob
  queue_as :default

  def perform(source_document)
    deduped = extract_and_dedup(source_document)
    create_and_reconcile(source_document, deduped)
  rescue => e
    source_document.update!(status: :failed, error_message: e.message)
    raise
  end

  # Phase 1: Extract commitments from PDF chunks and deduplicate within-document.
  # This phase is document-independent and can run in parallel across documents.
  def extract_and_dedup(source_document)
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
        with_retry { extractor.extract!(extractor.prompt(chunk, existing_commitments, policy_areas, departments)) }
      end

      all_extracted.concat(extractor.commitments.map { |c| c.merge("chunk_section" => chunk["section_title"]) })
    end

    deduplicate(all_extracted, source_document)
  end

  # Phase 2: Create commitments and reconcile against existing ones.
  # This phase must run sequentially so each document reconciles against prior documents.
  def create_and_reconcile(source_document, deduped)
    policy_areas = PolicyArea.all
    departments = Department.where(government: source_document.government)

    source = create_source(source_document)
    created_commitments = create_commitments(deduped, source_document.government, source, policy_areas, departments)

    reconcile_commitments(created_commitments, source_document, source)

    source_document.update!(
      status: :extracted,
      extraction_metadata: { commitment_count: created_commitments.size, chunk_count: deduped.size }
    )
  end

  private

  def with_retry(max_attempts: 5, &block)
    attempts = 0
    begin
      attempts += 1
      block.call
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Net::ReadTimeout, Errno::ECONNRESET => e
      raise if attempts >= max_attempts
      wait = 2**attempts
      Rails.logger.warn("Retry #{attempts}/#{max_attempts} after #{e.class}: #{e.message}. Waiting #{wait}s...")
      sleep(wait)
      retry
    end
  end

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
    by_chunk = commitments.group_by { |c| c["chunk_section"] }
    chunk_keys = by_chunk.keys

    titles_to_remove = Set.new

    chunk_keys.each_cons(2) do |chunk_a_key, chunk_b_key|
      deduper = CommitmentDeduplicator.create!(record: source_document)
      deduper.extract!(deduper.prompt(by_chunk[chunk_a_key], by_chunk[chunk_b_key]))

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
        update_commitment_if_drifted(commitment, data, source)
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

  def update_commitment_if_drifted(commitment, data, source)
    # Skip drift detection within the same source document — different phrasing
    # of the same commitment in the same document is not drift
    existing_source_doc_ids = commitment.sources.where.not(source_document_id: nil).pluck(:source_document_id)
    return if source.source_document_id.present? && existing_source_doc_ids.include?(source.source_document_id)

    tracked_fields = %w[title description original_text]
    changes = {}

    tracked_fields.each do |field|
      new_value = data[field]
      next if new_value.blank?
      next if commitment.send(field) == new_value
      changes[field] = new_value
    end

    return if changes.empty?

    old_values = {
      title: commitment.title,
      description: commitment.description,
      original_text: commitment.original_text
    }
    new_values = old_values.merge(changes.symbolize_keys)

    summarizer = CommitmentDriftSummarizer.create!(record: commitment)
    summarizer.extract!(summarizer.prompt(old_values, new_values))

    commitment.drift_source = source
    commitment.drift_change_summary = summarizer.change_summary
    commitment.update!(changes)
  end

  def reconcile_commitments(created_commitments, source_document, source)
    created_ids = created_commitments.values.map(&:id)
    active_commitments = Commitment.where(government: source_document.government)
                                   .where.not(id: created_ids)
                                   .where.not(status: :abandoned)

    return if active_commitments.empty?

    reconciler = CommitmentReconciler.create!(record: source_document)
    reconciler.extract!(reconciler.prompt(created_commitments.values, active_commitments))

    (reconciler.update_existing || []).each do |entry|
      existing = Commitment.find_by(id: entry["existing_commitment_id"])
      new_commitment = created_commitments.values.find { |c| c.title == entry["new_commitment_title"] }
      next unless existing && new_commitment

      data = {
        "title" => new_commitment.title,
        "description" => new_commitment.description,
        "original_text" => new_commitment.original_text
      }
      update_commitment_if_drifted(existing, data, source)

      new_commitment.commitment_sources.update_all(commitment_id: existing.id)
      new_commitment.destroy!
      created_commitments.delete(entry["new_commitment_title"])
    end

    (reconciler.abandoned || []).each do |entry|
      next unless entry["confidence"].to_f >= 0.6
      commitment = Commitment.find_by(id: entry["commitment_id"])
      next unless commitment

      commitment.abandonment_reason = entry["reason"]
      commitment.update!(status: :abandoned)
    end
  end
end
