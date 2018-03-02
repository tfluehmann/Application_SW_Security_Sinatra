require 'sinatra'
require 'json'
require 'sinatra/base'
require 'sinatra/sequel'
require 'sequel'
require 'sqlite3'
require 'app'
require 'db'
require 'customer'

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

  put '/customer/:name' do
    content_type :json
    Customer.create(name: params[:name], last_name: params[:last_name], address: params[:address])
    status 200
    "customer created".to_json
  rescue Sequel::UniqueConstraintViolation => e
    puts e.message
    status 409
    "already exists"
  end

  delete '/customer/:name' do
    content_type :json
    Customer.where(name: params[:name]).first.destroy
    status 200
    "customer deleted".to_json
  rescue
    status 404
    "customer not found"
  end
end

