require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "pry"
require "sinatra/content_for"

configure do 
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  set :erb, :escape_html => true
end

helpers do 
  def list_complete?(list)
    todos_remaining_count(list) == 0  && todos_count(list) > 0 
  end

  def list_class(list)
    "complete" if list_complete?(list) #to be refactored as a conditional if new conditions arise
  end

  def todos_remaining_count(list)
    list[:todos].select { |todo| todo[:completed] == false }.size
  end

  def todos_count(list)
    list[:todos].size
  end

  def sort_lists(lists, &block)
    completed_list, uncompleted_list = lists.partition { |list| list_complete?(list) } 

    uncompleted_list.each { |list| yield list, lists.index(list) }
    completed_list.each { |list| yield list, lists.index(list) }
  end

  def sort_todos(todos, &block)
    completed_todos, uncompleted_todos = todos.partition { |todo| todo[:completed] } 

    uncompleted_todos.each { |todo| yield todo, todos.index(todo) }
    completed_todos.each { |todo| yield todo, todos.index(todo) } 
  end
end

def load_list(list_id) 
  list = session[:lists].find { |list| list[:list_id] == list_id } 
  return list if list

  session[:error] = "The specified list was not found"
  redirect "/lists"
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

def next_todo_id(todos)
  max = todos.map { |todo| todo[:id] }.max || 0 
  max + 1
end

def next_list_id(lists)
  max = lists.map { |list| list[:list_id] }.max || 0 
  max + 1
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
    id = next_list_id(session[:lists])
    session[:lists] << { list_id: id, name: list_name, todos: [] }
    session[:success] = "The new list has been created succesfully!"
    redirect "/lists"
  end
end

# display a list 
get "/lists/:list_id" do 
  list_id = params[:list_id].to_i
  @list_id = params[:list_id] 
  
  @list = load_list(list_id) 
  @list_name = session[:lists].find { |list| list[:list_id] == list_id }[:name] 

  erb :list
end

# edit a list
get "/lists/:list_id/edit" do 
  list_id = params[:list_id].to_i
  @list_id = params[:list_id]

  @list = load_list(list_id) 
  erb :edit_list
end

# rename an existing list
post "/lists/:list_id" do 
  current_list_name = params[:list_name].strip
  list_id = params[:list_id].to_i
  @list = load_list(list_id) 
  @list_id = params[:list_id]
  
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

#delete a list 
post "/lists/:list_id/delete" do 
  id = params[:list_id].to_i
  session[:lists].reject! { |list| list[:list_id] == id } 
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = "The list was deleted succesfully" 
    redirect "/lists"
  end
end

# add a new Todo to the list
post "/lists/:list_id/todos" do 
  current_todo_name = params[:todo].strip
  list_id = params[:list_id].to_i
  @list_id = params[:list_id]
  
  @list = load_list(list_id) 
  @list_name = @list[:name]

  error = error_for_todoname?(current_todo_name)

  if error
    session[:error] = error
    erb :list
  else
    id = next_todo_id(@list[:todos])

    @list[:todos] << { id: id, name: params[:todo], completed: false }
    session[:success] = "The todo has been added succesfully"
    redirect "/lists/#{list_id}"
  end
end

# delete a Todo from the list
post "/lists/:list_id/todos/:todo_id/delete" do 
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id) 
  
  todo_id = params[:todo_id].to_i
  @list[:todos].reject! { |todo| todo[:id] == todo_id }

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "The todo has been deleted"
    redirect "/lists/#{@list_id}"
  end
end

# mark a a Todo as completed
post "/lists/:list_id/todos/:todo_id" do 
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id) 

  todo_id = params[:todo_id].to_i

  is_completed = params[:completed] == "true"
  selected_todo = @list[:todos].find { |todo| todo[:id] == todo_id }
  selected_todo[:completed] = is_completed

  session[:success] = "The todo has been updated"
  redirect "/lists/#{@list_id}"
end

# marking all the Todos of a single list as completed
post "/lists/:list_id/complete_all" do 
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id) 

  @list[:todos].each { |todo| todo[:completed] = true }
  session[:success] = "All the todos have been completed"
  redirect "/lists/#{@list_id}"
end
