class Avo::Resources::Evidence < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

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
end
