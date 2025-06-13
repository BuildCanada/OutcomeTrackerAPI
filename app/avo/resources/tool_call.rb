class Avo::Resources::ToolCall < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }
  
  def fields
    field :id, as: :id
    field :message, as: :belongs_to
    field :tool_call_id, as: :text
    field :name, as: :text
    field :arguments, as: :code
  end
end
