require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "pry"
require "sinatra/content_for"

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
  list_name = params[:list_name].strip #"sanitizing" the input string asap

  error = error_for_listname?(list_name)

  if error  
    session[:error] = error 
    erb :new_list
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The new list has been created succesfully!"
    redirect "/lists"
  end
end

def error_for_listname?(list_name)
  return "List name must only include alphanumeric characters and must be between 1 and 50 characters long." if invalid_name?(list_name) 
  return "List name must be unique" if already_used_name?(list_name)
end

def error_for_todoname?(todo_name)
  return "Todo name must only include alphanumeric characters and must be between 1 and 50 characters long." if invalid_name?(todo_name) 
end

def invalid_name?(name) 
  !name.match?(/^[\w ]{1,50}$/i) 
end

def already_used_name?(list_name)
  session[:lists].any? { |list| list[:name] == list_name }
end

get "/lists/:id" do 
  list_id = params[:id].to_i
  
  @list = session[:lists][list_id]
  @list_name = @list[:name]

  erb :list
end

get "/lists/:id/edit" do 
  list_id = params[:id].to_i
  @list_id = params[:id]

  @list = session[:lists][list_id]
  erb :edit_list
end

post "/lists/:id" do 
  current_list_name = params[:list_name].strip
  list_id = params[:id].to_i
  @list = session[:lists][list_id]
  
  error = error_for_listname?(current_list_name)

  if error
    session[:error] = error
    erb :edit_list

  else
    @list[:name] = current_list_name
    session[:success] = "The list has been renamed successfully"
    redirect "/lists/#{list_id}"
  end
end

post "/lists/:id/delete" do 
  id = params[:id].to_i
  session[:success] = "The list was deleted succesfully" if  session[:lists].delete_at(id) 
  redirect "/lists"
end

post "/lists/:id/todos" do 
  current_todo_name = params[:todo].strip
  list_id = params[:id].to_i
  
  @list = session[:lists][list_id]
  @list_name = @list[:name]

  error = error_for_todoname?(current_todo_name)

  if error
    session[:error] = error
    erb :list
  else
    @list[:todos] << { name: params[:todo], completed: false }
    session[:success] = "The todo has been added succesfully"
    redirect "/lists/#{list_id}"
  end
end
