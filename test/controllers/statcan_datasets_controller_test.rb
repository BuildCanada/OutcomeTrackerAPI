require "test_helper"

class StatcanDatasetsControllerTest < ActionDispatch::IntegrationTest
  test "should show dataset" do
    dataset = statcan_datasets(:synced)

    get statcan_dataset_url(dataset)

    assert_response :success
    assert_equal "application/json; charset=utf-8", response.content_type

    json_response = JSON.parse(response.body)
    assert_equal dataset.id, json_response["id"]
    assert_equal dataset.name, json_response["name"]
  end

  test "should return 404 for non-existent dataset" do
    get statcan_dataset_url(id: 99999)

    assert_response :not_found
  end
end
