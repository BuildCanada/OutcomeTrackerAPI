class Minister < ApplicationRecord
  belongs_to :government
  belongs_to :department

  has_one_attached :photo

  def self.ransackable_attributes(auth_object = nil)
    [ "first_name", "last_name", "title", "constituency", "province", "party" ]
  end

  def compound_name
    "#{title} (#{full_name})"
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def hill_office
    contact_data&.dig("offices")&.find { |o| o["type"]&.match?(/hill/i) }
  end

  def constituency_offices
    contact_data&.dig("offices")&.select { |o| !o["type"]&.match?(/hill/i) } || []
  end
end
