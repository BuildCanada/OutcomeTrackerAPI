class Avo::Resources::Chat < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :model_id, as: :text
    field :record, as: :belongs_to
    field :record_type, as: :text
  end
end
