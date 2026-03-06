require "test_helper"

class CriterionTest < ActiveSupport::TestCase
  test "valid criterion with required fields" do
    criterion = criteria(:defence_completion)
    assert criterion.valid?
  end

  test "requires description" do
    criterion = Criterion.new(
      commitment: commitments(:defence_spending),
      category: :completion,
      status: :not_assessed
    )
    assert_not criterion.valid?
    assert_includes criterion.errors[:description], "can't be blank"
  end

  test "category enum values" do
    assert criteria(:defence_completion).completion?
    assert criteria(:defence_success).success?
    assert criteria(:defence_progress).progress?
    assert criteria(:defence_failure).failure?
  end

  test "status enum values" do
    criterion = criteria(:defence_completion)
    assert criterion.not_assessed?

    criterion.status = :met
    assert criterion.met?
  end

  test "belongs to commitment" do
    criterion = criteria(:defence_success)
    assert_equal commitments(:defence_spending), criterion.commitment
  end

  test "default status is not_assessed" do
    criterion = Criterion.new
    assert criterion.not_assessed?
  end

  test "default position is 0" do
    criterion = Criterion.new
    assert_equal 0, criterion.position
  end
end
