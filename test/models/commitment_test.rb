require "test_helper"

class CommitmentTest < ActiveSupport::TestCase
  test "valid commitment with required fields" do
    commitment = commitments(:defence_spending)
    assert commitment.valid?
  end

  test "requires title" do
    commitment = Commitment.new(
      government: governments(:canada),
      description: "Some description",
      commitment_type: :legislative,
      status: :not_started
    )
    assert_not commitment.valid?
    assert_includes commitment.errors[:title], "can't be blank"
  end

  test "requires description" do
    commitment = Commitment.new(
      government: governments(:canada),
      title: "Some title",
      commitment_type: :legislative,
      status: :not_started
    )
    assert_not commitment.valid?
    assert_includes commitment.errors[:description], "can't be blank"
  end

  test "commitment_type enum values" do
    commitment = commitments(:defence_spending)
    assert commitment.spending?

    commitment.commitment_type = :legislative
    assert commitment.legislative?
  end

  test "status enum values" do
    commitment = commitments(:defence_spending)
    assert commitment.in_progress?

    commitment.status = :completed
    assert commitment.completed?
  end

  test "belongs to government" do
    commitment = commitments(:defence_spending)
    assert_equal governments(:canada), commitment.government
  end

  test "has many sources through commitment_sources" do
    commitment = commitments(:defence_spending)
    assert_includes commitment.sources, sources(:liberal_platform)
    assert_includes commitment.sources, sources(:budget_2025)
  end

  test "parent-child relationship" do
    parent = commitments(:defence_spending)
    child = commitments(:child_commitment)

    assert_equal parent, child.parent
    assert_includes parent.children, child
  end

  test "has many commitment_sources" do
    commitment = commitments(:defence_spending)
    assert_equal 2, commitment.commitment_sources.count
  end

  test "has many criteria with scoped accessors" do
    commitment = commitments(:defence_spending)
    assert_equal 1, commitment.success_criteria.count
    assert_equal 1, commitment.completion_criteria.count
    assert_equal 1, commitment.progress_criteria.count
  end

  test "has many departments through commitment_departments" do
    commitment = commitments(:defence_spending)
    assert_includes commitment.departments, departments(:finance)
  end

  test "lead department association" do
    commitment = commitments(:defence_spending)
    assert_equal departments(:finance), commitment.lead_department
  end

  test "destroying commitment cascades to children" do
    commitment = commitments(:defence_spending)
    assert_difference "Commitment.count", -2 do
      commitment.destroy
    end
  end

  test "destroying commitment cascades to sources and criteria" do
    commitment = commitments(:defence_spending)
    assert_difference "CommitmentSource.count", -2 do
      assert_difference "Criterion.count", -4 do
        assert_difference "CommitmentDepartment.count", -1 do
          commitment.destroy
        end
      end
    end
  end

  test "default status is not_started" do
    commitment = Commitment.new
    assert commitment.not_started?
  end

  test "default metadata is empty hash" do
    commitment = Commitment.new
    assert_equal({}, commitment.metadata)
  end
end
