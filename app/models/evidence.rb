class Evidence < ApplicationRecord
  belongs_to :activity
  belongs_to :promise
  belongs_to :linked_by, class_name: "User", optional: true
  belongs_to :reviewed_by, class_name: "User", optional: true

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
  end
end
