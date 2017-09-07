REDIS_HOST = ENV['REDIS_HOST'] || 'redis' 
REDIS_PORT = ENV['REDIS_PORT'] || 6379 
REDIS_DB = ENV['REDIS_DB'] || 0
REDIS_CONFIG = "redis://#{REDIS_HOST}:#{REDIS_PORT}/#{REDIS_DB}"
PORT = (IO.read('/run/secrets/messenger_port') rescue 5000)
