# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
puts "Destroying Messages...!"
Message.destroy_all
puts "Destroying Bookings...!"
Booking.destroy_all
puts "Destroying Availabilities...!"
Availability.destroy_all
puts "Destroying Users...!"
User.destroy_all
puts "Destroying Clients...!"
Client.destroy_all


joel = User.create!(email: "joel.durafourd@gmail.com", password: "123456", first_name: "Joel", last_name: "Durafourd")
joel.photo.attach(io: URI.open(Cloudinary::Utils.cloudinary_url("https://res.cloudinary.com/dxljoz6af/image/upload/v1723853860/production/fhhqf66coc61478cvs7743b4dfx2.jpg", size: '300x300', format: 'png')), filename: 'avatar.png')
puts "Created #{joel}!"

nakia = User.create!(email: "n@mail.com", password: "123456", first_name: "Bo Wen", last_name: "Zhong")
puts "Created #{nakia}!"

emilie = User.create!(email: "noctis@gmail.com", password: "123456", first_name: "Noctis", last_name: "LucisCaelum")
puts "Created #{emilie}!"

ayako = User.create!(email: "three.peach.0524@gmail.com", password: "123456", first_name: "Ayako", last_name: "Okawa")
puts "Created #{ayako}!"

user1 = User.create!(email: "john.doe@email.com", password: "123456", first_name: "John", last_name: "Doe")
puts "Created #{user1}!"

user2 = User.create!(email: "jane.smith@email.com", password: "password123", first_name: "Jane", last_name: "Smith")
puts "Created #{user2}!"

user3 = User.create!(email: "michael.jones@email.com", password: "securepass", first_name: "Michael", last_name: "Jones")
puts "Created #{user3}!"

user4 = User.create!(email: "emily.wilson@email.com", password: "p@ssw0rd", first_name: "Emily", last_name: "Wilson")
puts "Created #{user4}!"

user5 = User.create!(email: "david.brown@email.com", password: "david123", first_name: "David", last_name: "Brown")
puts "Created #{user5}!"


client1 = Client.create!(lineid: "ABC1234", phone_number: "555-0101", name: "Alice Johnson", nickname: "AliceJ1")
puts "Created #{client1}!"

client2 = Client.create!(lineid: "XYZ5678", phone_number: "555-0102", name: "Bob Smith", nickname: "BobS2")
puts "Created #{client2}!"

client3 = Client.create!(lineid: "LMN9101", phone_number: "555-0103", name: "Charlie Brown", nickname: "CharlieB3")
puts "Created #{client3}!"

client4 = Client.create!(lineid: "DEF2345", phone_number: "555-0104", name: "Diana Ross", nickname: "DianaR4")
puts "Created #{client4}!"

client5 = Client.create!(lineid: "GHI6789", phone_number: "555-0105", name: "Edward White", nickname: "EdwardW5")
puts "Created #{client5}!"

client6 = Client.create!(lineid: "JKL0123", phone_number: "555-0106", name: "Fiona Green", nickname: "FionaG6")
puts "Created #{client6}!"

client7 = Client.create!(lineid: "MNO4567", phone_number: "555-0107", name: "George Black", nickname: "GeorgeB7")
puts "Created #{client7}!"

client8 = Client.create!(lineid: "PQR8901", phone_number: "555-0108", name: "Hannah Blue", nickname: "HannahB8")
puts "Created #{client8}!"

client9 = Client.create!(lineid: "STU2345", phone_number: "555-0109", name: "Ian Gray", nickname: "IanG9")
puts "Created #{client9}!"

client10 = Client.create!(lineid: "VWX6789", phone_number: "555-0110", name: "Jane White", nickname: "JaneW10")
puts "Created #{client10}!"

start_date = Date.new(2024, 8, 19) # Monday of the week
end_date = start_date + 4 # Friday of the week

# Loop through each day from Monday to Friday
(start_date..end_date).each do |date|
  # Create morning shift availability
  morning_availability = Availability.create!(
    start_time: DateTime.new(date.year, date.month, date.day, 8, 0, 0),
    end_time: DateTime.new(date.year, date.month, date.day, 12, 0, 0),
    user_id: joel.id
  )
  puts "Created morning availability for #{date.strftime('%Y-%m-%d')}!"

  # Create afternoon shift availability
  afternoon_availability = Availability.create!(
    start_time: DateTime.new(date.year, date.month, date.day, 13, 0, 0),
    end_time: DateTime.new(date.year, date.month, date.day, 18, 0, 0),
    user_id: joel.id
  )
  puts "Created afternoon availability for #{date.strftime('%Y-%m-%d')}!"
end

# Create Bookings
booking1 = Booking.create!(
  start_time: DateTime.new(2024, 8, 19, 8, 0, 0), # Example time slot within the availability
  end_time: DateTime.new(2024, 8, 19, 9, 0, 0),
  status: 1, # Assuming 1 corresponds to a status like 'confirmed'
  user_id: joel.id,
  client_id: client1.id,
  title: 'Consultation with Alice',
  description: 'Discussing project details with Alice Johnson.'
)
puts "Created #{booking1}!"

booking2 = Booking.create!(
  start_time: DateTime.new(2024, 8, 19, 9, 0, 0), # Example time slot within the availability
  end_time: DateTime.new(2024, 8, 19, 10, 0, 0),
  status: 1,
  user_id: joel.id,
  client_id: client2.id,
  title: 'Consultation with Bob',
  description: 'Discussion with Bob Smith about upcoming tasks.'
)
puts "Created #{booking2}!"

booking3 = Booking.create!(
  start_time: DateTime.new(2024, 8, 21, 10, 0, 0), # Example time slot within the availability
  end_time: DateTime.new(2024, 8, 21, 11, 0, 0),
  status: 1,
  user_id: joel.id,
  client_id: client3.id,
  title: 'Consultation with Charlie',
  description: 'Meeting with Charlie Brown to review progress.'
)
puts "Created #{booking3}!"

booking4 = Booking.create!(
  start_time: DateTime.new(2024, 8, 22, 13, 0, 0), # Example time slot within the availability
  end_time: DateTime.new(2024, 8, 22, 14, 0, 0),
  status: 1,
  user_id: joel.id,
  client_id: client4.id,
  title: 'Consultation with Diana',
  description: 'Discussing contract terms with Diana Ross.'
)
puts "Created #{booking4}!"

booking5 = Booking.create!(
  start_time: DateTime.new(2024, 8, 23, 14, 0, 0), # Example time slot within the availability
  end_time: DateTime.new(2024, 8, 23, 15, 0, 0),
  status: 1,
  user_id: joel.id,
  client_id: client5.id,
  title: 'Consultation with Edward',
  description: 'Meeting with Edward White for project planning.'
)
puts "Created #{booking5}!"

booking6 = Booking.create!(
  start_time: DateTime.new(2024, 8, 23, 15, 0, 0), # Example time slot within the availability
  end_time: DateTime.new(2024, 8, 23, 16, 0, 0),
  status: 1,
  user_id: joel.id,
  client_id: client6.id,
  title: 'Consultation with Fiona',
  description: 'Consultation with Fiona Green on upcoming deliverables.'
)
puts "Created #{booking6}!"

booking7 = Booking.create!(
  start_time: DateTime.new(2024, 8, 21, 16, 0, 0), # Example time slot within the availability
  end_time: DateTime.new(2024, 8, 21, 17, 0, 0),
  status: 1,
  user_id: joel.id,
  client_id: client7.id,
  title: 'Consultation with George',
  description: 'Discussing project milestones with George Black.'
)
puts "Created #{booking7}!"

booking8 = Booking.create!(
  start_time: DateTime.new(2024, 8, 22, 17, 0, 0), # Example time slot within the availability
  end_time: DateTime.new(2024, 8, 22, 18, 0, 0),
  status: 1,
  user_id: joel.id,
  client_id: client8.id,
  title: 'Consultation with Hannah',
  description: 'Meeting with Hannah Blue to finalize project details.'
)
puts "Created #{booking8}!"

booking9 = Booking.create!(
  start_time: DateTime.new(2024, 8, 20, 8, 0, 0), # Example time slot on the next day
  end_time: DateTime.new(2024, 8, 20, 9, 0, 0),
  status: 1,
  user_id: joel.id,
  client_id: client9.id,
  title: 'Consultation with Ian',
  description: 'Consultation with Ian Gray to review project status.'
)
puts "Created #{booking9}!"

booking10 = Booking.create!(
  start_time: DateTime.new(2024, 8, 20, 9, 0, 0), # Example time slot on the next day
  end_time: DateTime.new(2024, 8, 20, 10, 0, 0),
  status: 1,
  user_id: joel.id,
  client_id: client10.id,
  title: 'Consultation with Jane',
  description: 'Meeting with Jane White to discuss project goals.'
)
puts "Created #{booking10}!"
