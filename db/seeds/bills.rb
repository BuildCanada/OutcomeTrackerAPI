require 'json'

puts "Seeding Bills..."

api_bills_array = JSON.parse(File.read("db/seeds/bills.json"))

api_bills_array.each do |api_data|
  attributes = Bill.attributes_from_api(api_data)
  bill = Bill.find_or_create_by(bill_id: attributes[:bill_id]) do |b|
    b.assign_attributes(attributes)
  end

  if bill.persisted?
    if bill.previously_new_record?
      puts "✓ #{bill.bill_number_formatted} - created"
    else
      puts "✓ #{bill.bill_number_formatted} - already exists"
    end
  else
    puts "✗ #{bill.bill_number_formatted} - failed to create: #{bill.errors.full_messages.join(', ')}"
  end
end
