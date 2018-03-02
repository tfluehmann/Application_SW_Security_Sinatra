DB = Sequel.sqlite
DB.create_table :customer do
  primary_key :id
  String :last_name
  String :first_name
  String :address
end
class Customer < Sequel::Model
end
