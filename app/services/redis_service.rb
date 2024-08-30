require 'redis'

class RedisService
  attr_accessor :redis, :namespace_prefix

  def initialize
    config = redis_config
    @redis = Redis.new(url: config['url'], ssl_params: config['ssl_params'])
    @namespace_prefix = config['namespace_prefix']
  end

  # Set the string value of a key.
  #
  # @param [String] key
  # @param [String] value
  # @return [String, Boolean] `"OK"` or true, false if `:nx => true` or `:xx => true`
  def set(key, value)
    @redis.set(namespaced_key(key), value)
  end

  # Set one or more hash values.
  #
  # @param [String] key
  # @param [Array<String> | Hash<String, String>] attrs array or hash of fields and values
  # @return [Integer] The number of fields that were added to the hash
  def hset(key, *attrs)
    @redis.hset(namespaced_key(key), *attrs)
  end

  # Get the value of a key.
  #
  # @param [String] key
  # @return [String]
  def get(key)
    @redis.get(namespaced_key(key))
  end

  # @param [String] key
  # @return [TrueClass, FalseClass]
  def if_exists(key)
    get(key).present?
  end

  # Delete one or more keys.
  #
  # @param [String, Array<String>] keys
  # @return [Integer] number of keys that were deleted
  def del(*keys)
    namespaced_keys = keys.map { |key| namespaced_key(key) }
    @redis.del(*namespaced_keys)
  end

  # Set a key's time to live in seconds.
  #
  # @param [String] key
  # @param [Integer] seconds time to live
  # @param [Hash] options
  #   - `:nx => true`: Set expiry only when the key has no expiry.
  #   - `:xx => true`: Set expiry only when the key has an existing expiry.
  #   - `:gt => true`: Set expiry only when the new expiry is greater than current one.
  #   - `:lt => true`: Set expiry only when the new expiry is less than current one.
  # @return [Boolean] whether the timeout was set or not
  def expire(key, seconds, **options)
    @redis.expire(namespaced_key(key), seconds, **options)
  end

  private

  # Load Redis configuration from redis.yml
  #
  # @return [Hash] Redis configuration for the current environment
  def redis_config
    config_path = Rails.root.join('config', 'redis.yml')

    # Read and process the ERB in the file
    erb_result = ERB.new(File.read(config_path)).result

    # Parse the result as YAML with alias support
    YAML.safe_load(erb_result, aliases: true)[Rails.env]
  end

  # Prefix keys with a namespace to avoid collisions.
  #
  # @param [String] key
  # @return [String] namespaced key
  def namespaced_key(key)
    "#{@namespace_prefix}:#{Rails.env}:#{key}"
  end
end
