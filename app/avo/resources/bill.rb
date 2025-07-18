class Avo::Resources::Bill < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.search = {
    query: -> { query.ransack(bill_number_formatted_cont: params[:q], short_title_cont: params[:q], long_title_cont: params[:q], m: "or").result(distinct: false) }
  }

  def fields
    field :id, as: :id
    field :bill_id, as: :number, sortable: true
    field :bill_number_formatted, as: :text, sortable: true
    field :parliament_number, as: :number, sortable: true
    field :short_title, as: :text
    field :long_title, as: :textarea
    field :latest_activity, as: :textarea
    field :latest_activity_at, as: :date_time, sortable: true

    field :passed_house_first_reading_at, as: :date_time
    field :passed_house_second_reading_at, as: :date_time
    field :passed_house_third_reading_at, as: :date_time
    field :passed_senate_first_reading_at, as: :date_time
    field :passed_senate_second_reading_at, as: :date_time
    field :passed_senate_third_reading_at, as: :date_time
    field :received_royal_assent_at, as: :date_time

    field :data, as: :code, language: :json
    field :created_at, as: :date_time
    field :updated_at, as: :date_time
  end
end
