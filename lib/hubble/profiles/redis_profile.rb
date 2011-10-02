require 'redis'
require 'resque'
require 'nokogiri'

class RedisProfile

  attr_accessor :connection

  def connection
    @connection ||= ::Redis.new
  end

  alias_method :redis, :connection

  def get_topic(url)
    tid = topic_id(url)
    get_topic_by_id(tid)
  end

  def get_topic_by_id(id)
    v = redis.get(id)
    return nil unless v
    Marshal::load(v)
  end

  def save_topic(topic)
    tid = topic_id(topic.url)
    topic.id = tid
    redis.set(tid, Marshal::dump(topic))
    topic
  end

  def get_subscriber(callback)
    sid = sub_id(callback)
    v = redis.get(sid)
    return nil unless v
    Marshal::load(v)
  end

  def create_subscriber(subscriber)
    sid = sub_id(subscriber.callback)
    subscriber.id = sid
    redis.set(sid, Marshal::dump(subscriber))

    subscriber
  end

  def get_subscribers(topic)
    #todo fetch all as hashes
    keys = redis.smembers("#{topic.id}:subs")
    return [] if keys.count == 0

    redis.mget(*keys).map{ |d| s = Marshal::load(d); }
  end

  def subscribe(topic, sub)
    redis.sadd("#{topic.id}:subs", sub.id)
  end

  def get_last_content(key)
    l = redis.get("#{key}:last")
    return nil unless l
    Marshal::load(l)
  end

  def set_last_content(key, content)
    redis.set("#{key}:last", Marshal::dump(content))
  end

  def topic_id(topic_url)
    "topic:#{Digest::MD5.hexdigest(topic_url)}"
  end

  def sub_id(callback_url)
    "sub:#{Digest::MD5.hexdigest(callback_url)}"
  end


  #
  # command execution
  #
  class JobRunner
    @queue = :job_runner
    def self.perform(id, method)
      o = Hubble.profile.get_topic_by_id(id)
      o.send(method)
    end
  end

  def execute(obj, method, args=nil)
    Resque.enqueue(RedisProfile::JobRunner, obj.id, method)
  end

end
