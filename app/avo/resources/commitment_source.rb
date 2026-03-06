class Avo::Resources::CommitmentSource < Avo::BaseResource
  def fields
    field :id, as: :id
    field :source, as: :belongs_to
    field :section, as: :text
    field :reference, as: :text
    field :excerpt, as: :textarea
    field :commitment, as: :belongs_to
  end
end
