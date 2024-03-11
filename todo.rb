require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

get "/" do
  @lists = [ 
    { name: "groceries lunch", todos: [] }, 
    { name: "groceries supper", todos: [] }
  ]
  erb :lists 
end
