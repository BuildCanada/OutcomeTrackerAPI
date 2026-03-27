class Avo::Resources::Source < Avo::BaseResource
  self.includes = [ :government ]
  self.title = :title

  def fields
    field :id, as: :id
    field :title, as: :text
    field :source_type, as: :select, enum: ::Source.source_types
    field :source_type_other, as: :text, hide_on: [ :index ]
    field :url, as: :text
    field :date, as: :date
    field :government, as: :belongs_to
    field :commitment_sources, as: :has_many
  end
end
