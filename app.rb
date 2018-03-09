require 'sinatra'
require 'json'
require 'sinatra/base'
require 'sinatra/sequel'
require 'sequel'
require 'sqlite3'
require 'json/jwt'
require 'app'
require 'db'
require 'customer'
require 'base64'

Customer.find_or_create(name: "bob", 
                        last_name: "marley",
                        address: "jamaika",
                        balance: 1000,
                        password: 'password')

class App < Sinatra::Base
  before do
    content_type :json
  end

=begin
  def authorized?
    customer = customer(auth.credentials.first) rescue nil
    auth.provided? &&
      auth.basic? &&
      auth.credentials &&
      customer &&
      auth.credentials.last == customer.password
  end
=end

  def authorized?
    encoded_token = env['HTTP_AUTHORIZATION'].split(' ').last
    decoded_token = Base64.urlsafe_decode64(encoded_token)
    jwt = JSON::JWT.decode(decoded_token) 
    customer = customer(jwt[:sub])
    return jwt && customer
  end

  def customer(name = nil)
    @customer ||= Customer.find(name: name)
  end

  def auth
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
  end

  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, "Oops... we need your login name & password\n"])
    end
  end

  def private_key
    @@private_key ||= OpenSSL::PKey::RSA.new(2048)
  end

  def public_key
    @@public_key ||= private_key.public_key
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
  end

  def jwt(customer)
    JSON::JWT.new(
      iss: 'sinatra',
      aud: 'sinatra',
      sub: customer.name,
      exp: (Time.now + 5 * 60).to_i,
      nbf: Time.now.to_i
    )
  end

  def authenticate(raw_token)

  end

  post '/authenticate' do
    customer = Customer.find(name: payload['username'])
    halt(404, 'Wrong username or password') if !customer || customer.password != payload['password'] 
    { access_token: Base64.urlsafe_encode64(jwt(customer).to_s) }.to_json
  end

  get '/' do
    "Hello from sinatra! The time is #{ Time.now.to_i } on #{ `hostname` }!"
  end

  post '/sign' do
    id_token = JSON::JWT.new(payload)
    id_token.kid = private_key.to_jwk.thumbprint
    id_token = id_token.sign(private_key, :RS256)
    { token: id_token.to_s }.to_json
  end

  post '/verify' do
    jwt = JSON::JWT.decode payload['token'], public_key 
    { payload: jwt }.to_json
  end

  post '/encrypt' do
    jwt = jwt = JSON::JWT.new(payload)
    jwe = jwt.encrypt(public_key)
    { payload: jwe.to_s }.to_json
  end

  post '/decrypt' do
    jwt = JSON::JWT.decode payload['payload'], private_key
    { payload: JSON::JWT.decode(jwt.plain_text, :skip_verification) }.to_json
  end

  ##
  # JSON example
  #
  get '/json' do
    {ok: "yes"}.to_json
  end

  post '/customer/:name' do |name|
    Customer.create(name: name, last_name: payload['last_name'], address: payload['address'])
    info("customer created")
  rescue Sequel::UniqueConstraintViolation => e
    status 409
    error("already exists")
  end

  get '/customer/:name' do |name|
    status 200
    Customer.find(name: name).to_json
  rescue
    status 404
    error("customer not found")
  end

  delete '/customer/:name' do |name|
    Customer.find(name: name).destroy
    status 200
    info("customer deleted")
  rescue
    status 404
    error("customer not found")
  end

  post '/customer/:sender/transaction/:receiver' do |sender, receiver|
    protected!
    receiver = Customer.find(name: receiver)
    halt 404, error("sender not found") if customer.nil?
    halt 404, error('You cannot use another bankaccount') if customer.name != sender
    halt 404, error("receiver not found") if receiver.nil?
    if customer.transaction(receiver, payload['amount'].to_i)
      status 200
      info('transaction processed')
    else
      status 422
      error("Not enough balance")
    end
  rescue => err
    puts err.message
    status 400
    error(err.message)
  end
end
