class Avo::Resources::CriterionAssessment < Avo::BaseResource
  def fields
    field :id, as: :id
    field :criterion, as: :belongs_to
    field :previous_status, as: :select, enum: ::CriterionAssessment.previous_statuses
    field :new_status, as: :select, enum: ::CriterionAssessment.new_statuses
    field :source, as: :belongs_to
    field :evidence_notes, as: :textarea
    field :assessed_at, as: :date_time
  end
end
