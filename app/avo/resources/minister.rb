class Avo::Resources::Minister < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }
  #
  self.title = :compound_name

  def fields
    field :id, as: :id
    field :first_name, as: :text
    field :last_name, as: :text
    field :title, as: :text
    field :started_at, as: :date_time
    field :order_of_precedence, as: :number
    field :person_short_honorific, as: :text
    field :ended_at, as: :date_time
    field :avatar_url, as: :external_image
    field :role, as: :text
    field :government, as: :belongs_to
    field :department, as: :belongs_to
  end
end
