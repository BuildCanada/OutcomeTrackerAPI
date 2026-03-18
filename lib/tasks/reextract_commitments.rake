namespace :commitments do
  desc "Wipe existing commitments and re-extract from source PDFs"
  task reextract: :environment do
    government = Government.find_by!(slug: "federal")

    puts "Destroying existing commitment-related records for #{government.name}..."

    # Order matters for foreign key dependencies
    FeedItem.where(commitment: government.commitments).delete_all
    CommitmentEvent.where(commitment: government.commitments).delete_all
    CommitmentRevision.where(commitment: government.commitments).delete_all
    CommitmentStatusChange.where(commitment: government.commitments).delete_all
    CriterionAssessment.joins(criterion: :commitment).where(commitments: { government_id: government.id }).delete_all
    CommitmentMatch.where(commitment: government.commitments).delete_all
    Criterion.joins(:commitment).where(commitments: { government_id: government.id }).delete_all
    CommitmentDepartment.joins(:commitment).where(commitments: { government_id: government.id }).delete_all
    CommitmentSource.joins(:commitment).where(commitments: { government_id: government.id }).delete_all
    government.commitments.delete_all
    Source.where(government: government).destroy_all
    SourceDocument.where(government: government).destroy_all

    puts "All commitment data cleared."

    # Ensure policy areas exist (required for extraction)
    load Rails.root.join("db/seeds/policy_areas.rb")

    tracker_root = Rails.root.join("..")

    document_configs = [
      {
        title: "Liberal Platform 2025 - Canada Strong",
        source_type: :platform_document,
        url: "https://liberal.ca/canada-strong/",
        date: Date.new(2025, 4, 28),
        file: "2025-04-28-liberal-platform.pdf"
      },
      {
        title: "Speech from the Throne 2025",
        source_type: :speech_from_throne,
        url: "https://www.canada.ca/en/privy-council/campaigns/speech-throne/2025/speech-from-the-throne.html",
        date: Date.new(2025, 5, 27),
        file: "2025-05-27-speech-from-the-throne.pdf"
      },
      {
        title: "Budget 2025 - Canada Strong",
        source_type: :budget,
        url: "https://budget.canada.ca/2025/home-accueil-en.html",
        date: Date.new(2025, 11, 5),
        file: "2025-11-05-budget-2025.pdf"
      }
    ]

    # Create all SourceDocuments without triggering async processing
    source_documents = []
    SourceDocument.skip_callback(:commit, :after, :enqueue_processing!)
    begin
      document_configs.each do |doc|
        source_documents << SourceDocument.create!(
          government: government,
          title: doc[:title],
          source_type: doc[:source_type],
          url: doc[:url],
          date: doc[:date],
          document: File.open(tracker_root.join(doc[:file]))
        )
      end
    ensure
      SourceDocument.set_callback(:commit, :after, :enqueue_processing!)
    end

    # Phase 1: Extract + dedup all documents in parallel
    puts "\nPhase 1: Extracting commitments from all #{source_documents.size} documents in parallel..."
    processor = SourceDocumentProcessorJob.new
    results = {}

    threads = source_documents.map do |sd|
      Thread.new do
        puts "  [START] #{sd.title}"
        deduped = processor.extract_and_dedup(sd)
        puts "  [DONE]  #{sd.title} — #{deduped.size} commitments extracted"
        results[sd.id] = deduped
      end
    end

    threads.each(&:join)

    # Phase 2: Create commitments + reconcile sequentially (Platform → SFT → Budget)
    puts "\nPhase 2: Creating commitments sequentially (reconciling across documents)..."
    source_documents.each_with_index do |sd, i|
      puts "  [#{i + 1}/#{source_documents.size}] #{sd.title}..."
      processor.create_and_reconcile(sd, results[sd.id])
      count = Commitment.where(government: government).count
      puts "    Total commitments so far: #{count}"
    end

    total = Commitment.where(government: government).count
    puts "\nComplete! #{total} total commitments extracted from #{source_documents.size} documents."
    puts "  by type: #{Commitment.where(government: government).group(:commitment_type).count}"
  end
end
