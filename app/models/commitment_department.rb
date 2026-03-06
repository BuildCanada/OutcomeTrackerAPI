class CommitmentDepartment < ApplicationRecord
  belongs_to :commitment
  belongs_to :department
end
