require "em-synchrony"
require 'em-synchrony/em-hiredis'
require 'em-websocket'
require 'em-hiredis'
require 'redis-em-mutex'
require 'json'
require "./config/config"
require "./lib/redis"

def log msg
  print "#{Time.now} ===== #{msg}\n"
end

def redis
  RedisConnection.connection
end

def get_subscribers(subscribtion)
  @subscribers[subscribtion] ||= {} if subscribtion
end

def add_subscriber(uuid, socket, subscribtion)
  get_subscribers(subscribtion)[uuid] = socket if subscribtion
end 

def remove_subscriber(uuid, subscribtions)
  subscribtions.each {|s| get_subscribers(s).delete(uuid) if s }
end

STDOUT.sync = true
RedisConnection.config = REDIS_CONFIG
log "Started at port #{PORT}"

Encoding.default_external = "utf-8"
EM.epoll
EM.synchrony do
  @subscribers = {}

  RedisConnection.subscribe('messages') do |channel, message|
    Fiber.new do 
      parsed_message = JSON.parse(message) rescue {}
      log "PubSub message received: #{message}"
      subscribers = get_subscribers parsed_message['message']
      subscribers.each do |uuid, socket|
        socket.send(message)
      end
    end.resume
  end

  EM::WebSocket.run(host: "0.0.0.0", port: PORT) do |ws|
    ws.onopen do |handshake|
      Fiber.new do
        tids = []
        subscribtions = []
        uuid = rand(36**36).to_s(36)

        ws.onclose do 
          Fiber.new do 
            log "WebSocket closed"
            remove_subscriber uuid, subscribtions
          end.resume
        end

        ws.onerror do 
          log "!!!!!WebSocket Error!!!!!" 
          Fiber.new do 
            remove_subscriber uuid, subscribtions
          end.resume
        end

        ws.onmessage do |msg|
          Fiber.new do
            alive[:state] = true
            message = JSON.parse(msg) rescue {}
            log "WebSocket message received: #{JSON.dump message}"
            if message['message']
              add_subscriber uuid, ws, message['message']
              subscribtions << message['message']
            end
          end.resume
        end
      end.resume
    end
  end
end
