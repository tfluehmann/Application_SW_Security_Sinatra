require 'sinatra'
require 'json'
require 'sinatra/base'
require 'sinatra/sequel'
require 'sequel'
require 'sqlite3'
require 'app'
require 'db'
require 'customer'

Customer.find_or_create(name: "bob", 
                        last_name: "marley",
                        address: "jamaika",
                        balance: 1000,
                        password: 'password')

class App < Sinatra::Base
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
    protected!
    content_type :json
    receiver = Customer.find(name: receiver)
    halt 404, error("sender not found") if customer.nil?
    halt 404, error('You cannot use another bankaccount') if auth.credentials.first != sender
    halt 404, error("receiver not found") if receiver.nil?
    if customer.transaction(receiver, payload['amount'].to_i)
      info('transaction processed')
      status 200
    else
      status 422
      error("Not enough balance")
    end
  rescue => err
    puts err.message
    status 400
    error(err.message)
  end

  def authorized?
    customer = customer(auth.credentials.first) rescue nil
    auth.provided? &&
      auth.basic? &&
      auth.credentials &&
      customer &&
      auth.credentials.last == customer.password
  end

  def customer(name = nil)
    @customer ||= Customer.find(name: name)
  end

  def auth
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
  end

  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, "Oops... we need your login name & password\n"])
    end
  end
end
