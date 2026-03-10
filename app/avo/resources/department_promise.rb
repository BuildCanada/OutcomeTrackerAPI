class Avo::Resources::DepartmentPromise < Avo::BaseResource
  class << self
    def navigation_label = "Department promises [deprecated]"
  end

  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :is_lead, as: :boolean
    field :department, as: :belongs_to
    field :promise, as: :belongs_to
  end
end
