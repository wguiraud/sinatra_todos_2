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
  list_name = params[:list_name]

  if valid_list_name?(list_name)
    session[:lists] << { name: params[:list_name], todos: [] }
    session[:success] = "The new lists has been created succesfully!"
    redirect "/lists"
  else
    session[:error] = "Invalid list name. Please only use alphanumeric characters"
    erb :new_list
  end
end

def valid_list_name?(list_name)
  list_name.strip.match?(/^[\w ]{1,50}/i)
end

