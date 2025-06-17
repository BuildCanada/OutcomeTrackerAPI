class Avo::Resources::Entry < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }
  
  def fields
    field :id, as: :id
    field :feed, as: :belongs_to
    field :title, as: :text
    field :url, as: :text
    field :scraped_at, as: :date_time
    field :description, as: :textarea
    field :government, as: :belongs_to
  end
end
