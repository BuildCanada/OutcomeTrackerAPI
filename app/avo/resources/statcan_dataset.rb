class Avo::Resources::StatcanDataset < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :statcan_url, as: :text
    field :name, as: :text
    field :sync_schedule, as: :text
    field :current_data, as: :code
    field :last_synced_at, as: :date_time
  end
end
