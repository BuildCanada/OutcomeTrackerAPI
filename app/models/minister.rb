class Minister < ApplicationRecord
  belongs_to :government
  belongs_to :department

  def self.ransackable_attributes(auth_object = nil)
    [ "first_name", "last_name", "title" ]
  end

  def compound_name
    "#{title} (#{full_name})"
  end

  def full_name
    "#{first_name} #{last_name}"
  end
end
