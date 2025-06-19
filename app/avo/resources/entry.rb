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
    field :published_at, as: :date_time
    field :skip_reason, as: :date_time
    field :skipped_at, as: :date_time
    field :scraped_at, as: :date_time
    field :is_index, as: :boolean
    field :summary, as: :textarea
    field :activities, as: :has_many

    field :parsed_markdown, as: :markdown
  end
end
