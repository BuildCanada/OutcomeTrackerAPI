require "test_helper"

class MinisterTest < ActiveSupport::TestCase
  test "that compound_name is correct" do
    minister = ministers(:finance_minister)
    assert_equal "Deputy Prime Minister and Minister of Finance (Chrystia Freeland)", minister.compound_name
  end
end
