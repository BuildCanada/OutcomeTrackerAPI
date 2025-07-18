class Evidence < ApplicationRecord
  belongs_to :activity
  belongs_to :promise
  belongs_to :linked_by, class_name: "User", optional: true
  belongs_to :reviewed_by, class_name: "User", optional: true

  scope :impactful, -> { where.not(impact: "neutral") }

  def self.ransackable_attributes(auth_object = nil)
    [ "impact", "impact_reason", "link_reason", "link_type" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "promise", "activity" ]
  end

  def format_for_llm
    <<~XML
    <evidence>
      <title_or_summary>#{activity.title}</title_or_summary>
      <evidence_source_type>#{activity.entry.feed}</evidence_source_type>
      <evidence_date>#{linked_at}</evidence_date>
      <description_or_details>#{impact_reason}</description_or_details>
      <source_url>#{activity.entry.url}</source_url>
    </evidence>
    XML
  end

  after_commit do
    self.promise.set_last_evidence_date!
    self.promise.update_progress!
  end

  def search_result_title
    "Re: Promise #{promise&.concise_title} - #{activity&.title}"
  end
end
