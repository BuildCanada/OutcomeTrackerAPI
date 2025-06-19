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
    field :summary, as: :text
    field :source_url, as: :text
    field :info, as: :code
    field :published_at, as: :date_time
  end
end
