require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

configure do 
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

before do 
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

get "/lists" do 
  @lists = session[:lists]
  erb :lists 
end

get "/lists/new" do 
  session[:lists] << { name: "My first list", todos: [] }
  redirect "/lists"
end
