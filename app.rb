# app.rb
# HTTP Todo Server in Ruby (Sinatra)
# Author: bocaletto-luca
# License: MIT
#
# A modern in-memory REST API with health, version, metrics, logging & graceful shutdown.
#
# Run:
#   gem install sinatra json
#   ruby app.rb [--port PORT]
#
require 'sinatra'
require 'json'
require 'thread'

VERSION = '1.0.0'
STORE     = { todos: {}, next_id: 1 }
STORE_MUX = Mutex.new
METRICS   = { requests: 0 }
METRICS_MUX = Mutex.new

configure do
  set :bind, '0.0.0.0'
  set :port, ARGV.last.to_i > 0 ? ARGV.pop.to_i : 4567
  enable :logging
end

before do
  METRICS_MUX.synchronize { METRICS[:requests] += 1 }
  content_type :json
end

get '/healthz' do
  status 200
  'ok'
end

get '/version' do
  status 200
  VERSION.to_json
end

get '/metrics' do
  total = STORE_MUX.synchronize { STORE[:todos].size }
  metrics = METRICS_MUX.synchronize { METRICS.merge(total_todos: total) }
  metrics.to_json
end

get '/todos' do
  STORE_MUX.synchronize { STORE[:todos].values }.to_json
end

post '/todos' do
  payload = JSON.parse(request.body.read) rescue {}
  title = payload['title'].to_s.strip
  halt 400, { error: 'invalid payload' }.to_json if title.empty?

  todo = STORE_MUX.synchronize do
    id = STORE[:next_id]
    t = { id: id, title: title, completed: false }
    STORE[:todos][id] = t
    STORE[:next_id] += 1
    t
  end

  status 201
  todo.to_json
end

get '/todos/:id' do
  id = params['id'].to_i
  todo = STORE_MUX.synchronize { STORE[:todos][id] }
  halt 404, { error: 'not found' }.to_json unless todo
  todo.to_json
end

put '/todos/:id' do
  id = params['id'].to_i
  payload = JSON.parse(request.body.read) rescue {}
  halt 400, { error: 'invalid payload' }.to_json unless payload.is_a?(Hash)

  updated = STORE_MUX.synchronize do
    t = STORE[:todos][id] or next nil
    t[:title]     = payload['title']     if payload.key?('title')
    t[:completed] = payload['completed'] if payload.key?('completed')
    t
  end

  halt 404, { error: 'not found' }.to_json unless updated
  updated.to_json
end

delete '/todos/:id' do
  id = params['id'].to_i
  removed = STORE_MUX.synchronize { STORE[:todos].delete(id) }
  if removed
    status 204
    body ''
  else
    halt 404, { error: 'not found' }.to_json
  end
end

# Graceful shutdown on SIGINT
Signal.trap('INT') do
  puts "\n🔌 Shutdown signal received"
  exit
end
