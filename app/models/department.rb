class Department < ApplicationRecord
  belongs_to :government
  has_many :officials, class_name: "Minister", dependent: :destroy
  # role is Minister or Prime Minister
  has_one :minister, -> { where("role in (?)", [ "Minister", "Prime Minister" ]) }, class_name: "Minister"

  has_many :department_promises, dependent: :destroy
  has_many :promises, through: :department_promises
  has_many :lead_promises, -> { where(department_promises: { is_lead: true }) },
           through: :department_promises, source: :promise

  def self.ransackable_attributes(auth_object = nil)
    [ "display_name", "official_name" ]
  end
end
