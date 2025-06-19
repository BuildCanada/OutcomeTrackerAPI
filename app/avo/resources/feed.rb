class Avo::Resources::Feed < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :title, as: :text
    field :description, as: :textarea
    field :language, as: :text
    field :url, as: :text
    field :last_scraped, as: :date_time
    field :raw, as: :code
    field :government, as: :belongs_to

    field entries, as: :has_many
  end
end
