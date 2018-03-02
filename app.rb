require 'sinatra'
require 'json'
require 'sinatra/base'
require 'sinatra/sequel'
require 'sequel'
require 'sqlite3'
require 'app'
require 'db'
require 'customer'

Customer.find_or_create(name: "bob", last_name: "marley", address: "jamaika", balance: 1000)

class App < Sinatra::Base

  get '/' do
    content_type :json
    "Hello from sinatra! The time is #{ Time.now.to_i } on #{ `hostname` }!"
  end

  ##
  # JSON example
  #
  get '/json' do
    content_type :json
    {ok: "yes"}.to_json
  end

  post '/customer/:name' do |name|
    content_type :json
    Customer.create(name: name, last_name: payload['last_name'], address: payload['address'])
    info("customer created")
  rescue Sequel::UniqueConstraintViolation => e
    puts e.info
    status 409
    error("already exists")
  end

  get '/customer/:name' do |name|
    content_type :json
    status 200
    Customer.find(name: name).to_json
  rescue
    status 404
    error("customer not found")
  end

  delete '/customer/:name' do |name|
    content_type :json
    Customer.find(name: name).destroy
    status 200
    info("customer deleted")
  rescue
    status 404
    error("customer not found")
  end

  post '/customer/:sender/transaction/:receiver' do |sender, receiver|
    content_type :json
    sender = Customer.find(name: sender)
    receiver = Customer.find(name: receiver)
    halt 404, error("sender not found") if sender.nil?
    halt 404, error("receiver not found") if receiver.nil?
    amount = payload['amount'].to_i
    if(sender.balance >= amount)
      sender.update(balance: sender.balance - amount)
      receiver.update(balance: receiver.balance + amount)
      info('transaction processed')
      status 200
    else
      status 422
      error("Not enough balance")
    end
  rescue
    status 404
    error("customer not found")
  end

  def error(msg)
    message(:error, msg)
  end

  def info(msg)
    message(:info, msg)
  end

  def message(key, msg)
    { key => msg }.to_json
  end

  def payload
    @payload ||= JSON.parse(request.body.read)
    puts @payload
    @payload
  end
end

