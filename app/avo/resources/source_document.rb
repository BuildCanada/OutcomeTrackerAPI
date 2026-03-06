class Avo::Resources::SourceDocument < Avo::BaseResource
  self.includes = [ :government ]
  self.title = :title

  def fields
    field :id, as: :id
    field :title, as: :text
    field :source_type, as: :select, enum: ::Source.source_types
    field :document, as: :file
    field :url, as: :text
    field :date, as: :date
    field :status, as: :select, enum: ::SourceDocument.statuses, disabled: true
    field :error_message, as: :textarea, hide_on: :index
    field :extraction_metadata, as: :code, language: :json, hide_on: :index
    field :government, as: :belongs_to
    field :source, as: :has_one
  end
end
