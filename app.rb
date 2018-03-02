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
    "Hello from sinatra! The time is #{ Time.now.to_i } on #{ `hostname` }!"
  end

  ##
  # JSON example
  #
  get '/json' do
    content_type :json
    {ok: "yes"}.to_json
  end

  post '/customer/:customer_name' do
    name = params[:customer_name]

  end
end

