require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

get "/" do
  @lists = [ 
    { name: "groceries lunch"}, 
    { name: "groceries supper"}
  ]
  erb :lists 
end
