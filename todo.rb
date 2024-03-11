require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "pry"

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

# view all lists 
get "/lists" do 
  @lists = session[:lists]
  erb :lists 
end

# render the new list form 
get "/lists/new" do 
  erb :new_list
end

# create a new list
post "/lists" do 
  session[:lists] << { name: params[:list_name], todos: [] }
  redirect "/lists"
end

