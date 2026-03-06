class Avo::Resources::Commitment < Avo::BaseResource
  self.includes = [ :government, :parent, :superseded_by, :policy_area ]
  self.search = {
    query: -> { query.ransack(title_cont: params[:q], m: "or").result(distinct: false) }
  }

  self.title = :title

  def fields
    field :id, as: :id
    field :title, as: :text
    field :description, as: :textarea
    field :original_text, as: :textarea, hide_on: :index
    field :commitment_type, as: :select, enum: ::Commitment.commitment_types
    field :status, as: :select, enum: ::Commitment.statuses
    field :date_promised, as: :date
    field :target_date, as: :date
    field :last_assessed_at, as: :date_time
    field :region_code, as: :text
    field :party_code, as: :text

    field :government, as: :belongs_to
    field :policy_area, as: :belongs_to
    field :parent, as: :belongs_to
    field :superseded_by, as: :belongs_to
    field :lead_department, as: :has_one

    field :children, as: :has_many
    field :commitment_sources, as: :has_many
    field :criteria, as: :has_many
    field :commitment_departments, as: :has_many
  end
end
