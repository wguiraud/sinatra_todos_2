# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'pry'

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

before do
  session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

# view all lists
get '/lists' do
  @lists = session[:lists]
  erb :lists
end

# render the new list form
get '/lists/new' do
  erb :new_list
end

# create a new list
post '/lists' do
  list_name = params[:list_name].strip # "sanitizing" the input string asap

  error = error_for_list_name?(list_name)

  if error
    session[:error] = error
    erb :new_list
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The new list has been created succesfully!'
    redirect '/lists'
  end
end

def error_for_list_name?(list_name)
  if invalid_list_name?(list_name)
    return 'List name must only include alphanumeric characters and must be between 1 and 50 characters long.'
  end

  'List name must be unique' if already_used_list_name?(list_name)
end

def invalid_list_name?(list_name)
  !list_name.match?(/^[\w ]{1,50}$/i)
end

def already_used_list_name?(list_name)
  session[:lists].any? { |list| list[:name] == list_name }
end
