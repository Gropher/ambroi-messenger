module RedisConnection
  # This is the magical bit that gets mixed into your classes
  def redis
    RedisConnection.connection
  end

  def self.subscribe(name, &block)
    conn = EM::Hiredis.connect(RedisConnection.config)
    conn.subscribe(name)
    conn.on :message, &block
  end

  # Global, memoized, lazy initialized instance of a redis
  def self.connection
    Redis::EM::Mutex.setup(size: 10, url: RedisConnection.config, expire: 600) unless @connection
    @connection ||= EventMachine::Synchrony::ConnectionPool.new(size: 10) do
      EM::Hiredis.connect(RedisConnection.config)
    end
  end

  def self.config
    @connection_config
  end

  def self.config= config
    @connection_config = config
  end
end
