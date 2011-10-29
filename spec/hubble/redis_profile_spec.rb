require 'helper'
require 'hubble/profiles/redis_profile'

require 'redis/namespace'

describe RedisProfile do
  before do
    fail "set environment HUBBLE_TEST variable for redis test." unless ENV["HUBBLE_TEST"]
    if(@profile.nil?)
      @redis ||=Redis.new :db => 15 # Redis::Namespace.new(:test_hubble, :redis => Redis.new)
      @profile = RedisProfile.new
      @profile.connection = @redis
    end
    @redis.select 15
    @redis.flushdb
  end

  it "should get/save topic" do
    topic = Topic.new({:url=>"http://acme.org"})

    @profile.save_topic(topic)
    newtopic = @profile.get_topic(topic.url)
    topic.url.must_equal newtopic.url
    newtopic.id.must_equal "topic:4314890e486233f3500e193371ee5bc0"
  end


  it "should get/save subscriber" do
    s = Subscriber.new({:callback => "http://sub.org/callback", :secret => "s3cret", :id=> "subscriber_id!"})

    @profile.create_subscriber(s)
    new_s = @profile.get_subscriber(s.callback)

    new_s.callback.must_equal "http://sub.org/callback"
    new_s.secret.must_equal "s3cret"
    new_s.id.must_equal "sub:12f534186f587528aa4c1b67e4061842"
    new_s.verify_token.must_equal nil
    new_s.valid?.must_equal false
  end

end


