require "test_helper"

class BillTest < ActiveSupport::TestCase
  def bill_data
    bills(:one).data
  end

  test "sync_all handles empty list response" do
    BillsFetcher.stub :fetch, [] do
      assert_difference "Bill.count", 0 do
        Bill.sync_all()
      end
    end
  end

  test "sync_all inserts new bills" do
    data = bill_data().merge("BillId" => 2, "BillNumberFormatted" => "S-2")
    api_bills_array = [ data ]

    BillsFetcher.stub :fetch, api_bills_array do
      assert_difference "Bill.count", 1 do
        Bill.sync_all
      end
    end

    assert Bill.exists?(bill_id: data["BillId"])
  end

  test "sync_all updates existing bills" do
    data = bill_data().merge("ShortTitleEn" => "Updated Title")
    api_bills_array = [ data ]

    BillsFetcher.stub :fetch, api_bills_array do
      assert_no_difference "Bill.count" do
        Bill.sync_all
      end

      bill = Bill.find_by(bill_id: data["BillId"])
      assert_equal "Updated Title", bill.short_title
    end
  end

  test "attributes_from_api converts API data to model attributes" do
    data = bill_data()
    attributes = Bill.attributes_from_api(data)

    assert_equal 13539458, attributes[:bill_id]
    assert_equal "S-1", attributes[:bill_number_formatted]
    assert_equal 45, attributes[:parliament_number]

    assert_equal "", attributes[:short_title]
    assert_equal "An Act relating to railways", attributes[:long_title]
    assert_equal "Introduction and first reading on May 27, 2025 (Senate)", attributes[:latest_activity]

    assert_equal data, attributes[:data]

    assert_nil attributes[:passed_house_first_reading_at]
    assert_nil attributes[:passed_house_second_reading_at]
    assert_nil attributes[:passed_house_third_reading_at]
    assert_equal Time.parse("2025-05-26T20:00:00-04:00"), attributes[:passed_senate_first_reading_at]
    assert_nil attributes[:passed_senate_second_reading_at]
    assert_nil attributes[:passed_senate_third_reading_at]
    assert_nil attributes[:received_royal_assent_at]
    assert_equal Time.parse("2025-05-26T20:00:00-04:00"), attributes[:latest_activity_at]
  end
end
