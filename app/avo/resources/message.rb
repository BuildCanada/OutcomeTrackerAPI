class Avo::Resources::Message < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }
  
  def fields
    field :id, as: :id
    field :chat, as: :belongs_to
    field :role, as: :text
    field :content, as: :textarea
    field :model_id, as: :text
    field :input_tokens, as: :number
    field :output_tokens, as: :number
    field :tool_call, as: :belongs_to
  end
end
