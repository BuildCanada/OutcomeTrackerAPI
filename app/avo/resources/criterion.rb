class Avo::Resources::Criterion < Avo::BaseResource
  def fields
    field :id, as: :id
    field :category, as: :select, enum: ::Criterion.categories
    field :description, as: :textarea
    field :verification_method, as: :textarea
    field :status, as: :select, enum: ::Criterion.statuses
    field :evidence_notes, as: :textarea
    field :assessed_at, as: :date_time
    field :position, as: :number
    field :commitment, as: :belongs_to
    field :criterion_assessments, as: :has_many
  end
end
