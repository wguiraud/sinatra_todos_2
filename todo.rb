require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

configure do 
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

get "/" do
  redirect "/lists"
end

get "/lists" do 
  @lists = session[:lists]
  erb :lists 
end

