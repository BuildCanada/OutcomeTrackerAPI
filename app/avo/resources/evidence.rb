class Avo::Resources::Evidence < Avo::BaseResource
  class << self
    def navigation_label = "Evidences [deprecated]"
  end

  self.includes = [ :promise, :activity ]
  self.title = :search_result_title
  self.description = :search_result_description
  # self.attachments = []
  self.search = {
    query: -> { query.ransack(promise_concise_title_cont: params[:q], promise_description_cont: params[:q], promise_promise_id_cont: params[:q], activity_title_cont: params[:q], m: "or").result(distinct: false) }
  }

  def fields
    field :id, as: :id
    field :review, as: :boolean, name: "Reviewed", sortable: true

    field :impact_magnitude, as: :number, sortable: true
    field :impact, as: :text
    field :promise, as: :belongs_to
    field :impact_reason, as: :text

    field :activity, as: :belongs_to
    field :linked_at, as: :date_time, sortable: true
    field :linked_by, as: :belongs_to
    field :link_type, as: :text
    field :link_reason, as: :text
    field :reviewed_by, as: :belongs_to
    field :reviewed_at, as: :date_time
  end

  def self.ransackable_associations(auth_object = nil)
    [ "promise", "activity" ]
  end
end
