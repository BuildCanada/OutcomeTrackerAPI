class CommitmentSource < ApplicationRecord
  belongs_to :commitment
  belongs_to :source
end
