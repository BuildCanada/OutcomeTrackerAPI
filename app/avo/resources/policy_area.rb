class Avo::Resources::PolicyArea < Avo::BaseResource
  self.title = :name

  def fields
    field :id, as: :id
    field :name, as: :text
    field :slug, as: :text
    field :description, as: :textarea, hide_on: :index
    field :commitments, as: :has_many
  end
end
