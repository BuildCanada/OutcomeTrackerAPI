class Avo::Resources::CommitmentDepartment < Avo::BaseResource
  def fields
    field :id, as: :id
    field :is_lead, as: :boolean
    field :commitment, as: :belongs_to
    field :department, as: :belongs_to
  end
end
