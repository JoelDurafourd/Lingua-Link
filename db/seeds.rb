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


client1 = Client.create!(lineid: "ABC1234", phone_number: "555-0101", name: "Alice Johnson")
puts "Created #{client1}!"

client2 = Client.create!(lineid: "XYZ5678", phone_number: "555-0102", name: "Bob Smith")
puts "Created #{client2}!"

client3 = Client.create!(lineid: "LMN9101", phone_number: "555-0103", name: "Charlie Brown")
puts "Created #{client3}!"

client4 = Client.create!(lineid: "DEF2345", phone_number: "555-0104", name: "Diana Ross")
puts "Created #{client4}!"

client5 = Client.create!(lineid: "GHI6789", phone_number: "555-0105", name: "Edward White")
puts "Created #{client5}!"
