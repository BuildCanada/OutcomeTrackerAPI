class Avo::Resources::Activity < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :entry, as: :belongs_to
    field :government, as: :belongs_to
    field :title, as: :text
    field :details, as: :text
    field :source_url, as: :text
    field :info, as: :code
    field :publication_date, as: :date
    field :in_force_date, as: :date
  end
end
