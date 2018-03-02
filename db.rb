set :database, 'sqlite://foo.db'

# define database migrations. pending migrations are run at startup and
# are guaranteed to run exactly once per database.
migration "create the foos table" do
  database.create_table :customers do
    primary_key :id
    text        :name
    text        :last_name
    text        :address

    index :name, unique: true
  end
end if !database.table_exists?('customers')

