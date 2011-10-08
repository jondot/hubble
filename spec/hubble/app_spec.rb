require 'helper'
require 'pp'

require 'hubble/app'
require 'rack/test'
include Rack::Test::Methods



include Hubble

def app
  Hubble::App
end

def r
  last_response
end

def build_topic_from_url(url)
  Topic.new({:url=> url, :id=> "topic_id!"})
end

def build_subscriber_from(callback, secret)
  Subscriber.new({:callback => callback, :secret => secret, :id=> "subscriber_id!"})
end

describe Hubble::App do

  describe "hub" do
    it "should reject any mode other than subscribe and publish" do
      post '/',{ 'hub.mode'  => 'foo',
                 'hub.topic' => 'http://acme.org',
                 'hub.callback' => 'http://sub.org/callback',
                 'hub.verify'   => 'sync' }
      r.status.must_equal 400
      r.body.must_equal "Only 'subscribe', 'publish' are allowed for #{Hubble::PSHB::MODE}" 
    end
  end


  describe "when subscribing" do


    it "should at least contain topic, callback, and verify type" do
      post '/',{ 'hub.mode'  => 'subscribe',
                 #'hub.topic' => 'http://acme.org',
                 'hub.callback' => 'http://sub.org/callback',
                 'hub.verify'   => 'sync' }
      r.status.must_equal 400
      r.body.must_equal "Missing hub.callback, hub.topic, or hub.verify"

      
      post '/',{ 'hub.mode'  => 'subscribe',
                 'hub.topic' => 'http://acme.org',
                 #'hub.callback' => 'http://sub.org/callback',
                 'hub.verify'   => 'sync' }
      r.status.must_equal 400
      r.body.must_equal "Missing hub.callback, hub.topic, or hub.verify"


      post '/',{ 'hub.mode'  => 'subscribe',
                 'hub.topic' => 'http://acme.org',
                 'hub.callback' => 'http://sub.org/callback',
                 #'hub.verify'   => 'sync' 
               }
      r.status.must_equal 400
      r.body.must_equal "Missing hub.callback, hub.topic, or hub.verify"

      post '/',{ 'hub.mode'  => 'subscribe',
                 'hub.topic' => 'http://acme.org',
                 'hub.callback' => 'http://sub.org/callback',
                 'hub.verify'   => 'FOO sync' }
      r.status.must_equal 400
      r.body.must_equal "Missing hub.callback, hub.topic, or hub.verify"
    end

    
    it "should subscribe and validate given nonexisting subscriber" do
      subscriber = build_subscriber_from 'http://sub.org/callback', 's3cret'
      mock(subscriber).valid?.returns true
      mock(Subscriber).get_by_callback('http://sub.org/callback').returns nil

      topic = build_topic_from_url('http://acme.org')
      mock(Topic).get_by_url('http://acme.org').returns topic
      
      mock(topic).add_subscriber(subscriber)

      mock(Subscriber).create_and_validate('http://sub.org/callback', topic.url, 's3cret', 't0ken', nil).returns subscriber

      post '/',{ 'hub.mode'  => 'subscribe',
                 'hub.topic' => 'http://acme.org',
                 'hub.callback' => 'http://sub.org/callback',
                 'hub.secret' => 's3cret',
                 'hub.verify_token' => 't0ken',
                 'hub.verify'   => 'sync' }

      r.status.must_equal 204
      r.body.must_equal ''
    end


    it "should not subscribe to non existing topic" do
      mock(Topic).get_by_url('http://acme.org').returns nil
      post '/',{ 'hub.mode'  => 'subscribe',
                 'hub.topic' => 'http://acme.org',
                 'hub.callback' => 'http://sub.org/callback',
                 'hub.verify'   => 'sync' }
      r.status.must_equal 404
      r.body.must_equal "No such topic 'http://acme.org'"
    end


    it "should not subscribe given subscriber was never validated" do
      topic = build_topic_from_url 'http://acme.org'
      subscriber = build_subscriber_from 'http://sub.org/callback', 's3cret'

      # not valid
      mock(subscriber).valid?.returns false

      mock(Topic).get_by_url('http://acme.org').returns topic
      mock(Subscriber).get_by_callback('http://sub.org/callback').returns subscriber


      post '/',{ 'hub.mode'  => 'subscribe',
                 'hub.topic' => 'http://acme.org',
                 'hub.callback' => 'http://sub.org/callback',
                 'hub.verify'   => 'sync' }

      r.status.must_equal 409
      r.body.must_equal "The url 'http://sub.org/callback' was not validated yet. Try later."
    end

    it "should not subscribe given subscriber was CANNOT be validated" do
      topic = build_topic_from_url('http://acme.org')

      mock(Topic).get_by_url('http://acme.org').returns topic
      mock(Subscriber).get_by_callback('http://sub.org/callback').returns nil
      mock(Subscriber).create_and_validate('http://sub.org/callback', topic.url, 's3cret', 't0ken', nil).returns nil


      post '/',{ 'hub.mode'  => 'subscribe',
                 'hub.topic' => 'http://acme.org',
                 'hub.callback' => 'http://sub.org/callback',
                 'hub.verify'   => 'sync',
                 'hub.secret'   => 's3cret',
                 'hub.verify_token' => 't0ken' }
    
      r.status.must_equal 409
      r.body.must_equal "Cannot validate 'http://sub.org/callback'"
    end

    it "should subscribe" do
      topic = build_topic_from_url('http://acme.org')
      subscriber = build_subscriber_from 'http://sub.org/callback', 's3cret'

      mock(subscriber).valid?.returns true
      mock(Topic).get_by_url('http://acme.org').returns topic
      mock(Subscriber).get_by_callback('http://sub.org/callback').returns subscriber
      mock(topic).add_subscriber(subscriber)

      post '/',{ 'hub.mode'  => 'subscribe',
                 'hub.topic' => 'http://acme.org',
                 'hub.callback' => 'http://sub.org/callback',
                 'hub.verify'   => 'sync' }


      r.status.must_equal 204
    end
  end

  describe 'when publishing' do
    it "should have a url to publish out of" do
      post '/', {'hub.mode' => 'publish'}
      r.status.must_equal 400
      r.body.must_equal 'missing hub.url'
    end

    it "should ping subscribers about update" do
      topic = build_topic_from_url('http://acme.org')
      mock(Topic).get_by_url('http://acme.org').returns topic
      mock(topic).ping_subscribers!

      post '/', {'hub.mode' => 'publish', 'hub.url' => 'http://acme.org'}

      r.status.must_equal 204
      r.body.must_equal ''
    end

    it "should create a new topic and ping given non existing" do
      topic = build_topic_from_url('http://acme.org')
      mock(Topic).get_by_url('http://acme.org').returns nil
      mock(Topic).create('http://acme.org').returns topic
      mock(topic).ping_subscribers!

      post '/', {'hub.mode' => 'publish', 'hub.url' => 'http://acme.org'}

      r.status.must_equal 204
      r.body.must_equal ''
    end

    it "should create and validate" do
      callback = 'http://sub.org/callback'
      topic    = 'http://acme.org'
      secret   = 's3cret'
      vtoken   = 't0ken'
      challenge = 123

      mock(SimpleUUID::UUID).new.returns challenge
      mock(Subscriber.profile).create_subscriber(anything).returns "ok"

      query = {
        Hubble::PSHB::MODE  => "subscribe",
        Hubble::PSHB::TOPIC => topic,
        Hubble::PSHB::CHALLENGE => challenge.to_s,
        Hubble::PSHB::LEASE     => Hubble::LEASE_SECONDS,
        Hubble::PSHB::VTOKEN => vtoken
      }
 
      res = Object.new
      mock(res).code.times(2).returns(200)
      mock(res).body.returns(challenge.to_s)
  

      mock(HTTParty).get(callback, 
                         :follow_redirects=>false,
                         :query => query)
                    .returns(res)
      
      s = Subscriber.create_and_validate callback, topic, secret, vtoken, nil
      s.must_equal 'ok'
      
    end
  end
end







describe Topic do

  it "should build from url" do
    t = build_topic_from_url("http://acme.org")
    t.url.must_equal "http://acme.org"
    t.id.must_equal "topic_id!"
  end

  it "should get by url" do
    mock(Topic.profile).redis.stub!.get("topic:4314890e486233f3500e193371ee5bc0").returns(Marshal::dump(Topic.new({:url => "http://acme.org", :id=>"topic:4314890e486233f3500e193371ee5bc0" })))
    t = Topic.get_by_url("http://acme.org")
    t.url.must_equal "http://acme.org"
    t.id.must_equal  "topic:4314890e486233f3500e193371ee5bc0"
  end

  it "should create with url" do
    mock(Topic.profile).redis.stub!.set("topic:4314890e486233f3500e193371ee5bc0", Marshal::dump(Topic.new({:id => "topic:4314890e486233f3500e193371ee5bc0", :url => "http://acme.org" })))
    t = Topic.create("http://acme.org")
    t.url.must_equal "http://acme.org"
    t.id.must_equal  "topic:4314890e486233f3500e193371ee5bc0"
  end

  it "should add subscriber" do
    mock(Topic.profile).redis.stub!.sadd("topic_id!:subs",  'subscriber_id!')
    t = build_topic_from_url("http://acme.org")
    s = build_subscriber_from "http://sub.org/callback", "s3cret"

    t.add_subscriber(s)
  end

  it "should call publish hook upon publish" do
    t = build_topic_from_url("http://acme.org")
    mock(Topic.profile).execute(t, :publish)
    t.ping_subscribers!
  end

  it "should not even fetch nor publish if no subscribers" do
    t = build_topic_from_url("http://acme.org")
    mock(Topic.profile).get_subscribers(t).returns []
    dont_allow(t).fetch()

    t.publish
  end

  it "should fetch the source url if atom or rss, and success" do
    response = {
      :body => file_content('feed_new.xml'),
      :status => 200,
      :headers => { 'content-type' => 'application/atom+xml'}
    }

    stub_request(:get, "http://acme.org").to_return(response)
    t = build_topic_from_url("http://acme.org")
    t.fetch().wont_equal nil


    response[:headers]['content-type'] = 'application/rss+xml'
    stub_request(:get, "http://acme.org").to_return(response)
    t = build_topic_from_url("http://acme.org")
    t.fetch().wont_equal nil

    response[:headers]['content-type'] = 'application/poo+xml'
    stub_request(:get, "http://acme.org").to_return(response)
    t = build_topic_from_url("http://acme.org")
    t.fetch().must_equal nil

    response[:headers]['content-type'] = 'application/rss+xml'
    response[:status] = 500
    stub_request(:get, "http://acme.org").to_return(response)
    t = build_topic_from_url("http://acme.org")
    t.fetch().must_equal nil
  end

  it "should POST and NOT sign data when POSTing and subscriber has NO secret" do
    topic_response = {
      :body => file_content('feed_new.xml'),
      :status => 200,
      :headers => { 'content-type' => 'application/atom+xml'}
    }

    stub_request(:get, "http://acme.org").to_return(topic_response)

    t = build_topic_from_url("http://acme.org")
    s = Subscriber.new({ :callback => "http://sub.org/callback",
                         :verify_token => "t0ken",
                         :id => "subscriber_id!" })

    mock(Topic.profile).get_subscribers(t).returns [s]
    mock(Topic.profile).get_last_content(t.id).returns nil
    mock(Topic.profile).set_last_content(t.id, anything)
    mock(t).post(s, "application/atom+xml", file_content('feed_new.xml'))

    t.publish
  end

  it "should POST and sign data when POSTing and subscriber has secret" do
    t = build_topic_from_url("http://acme.org")
    s = Subscriber.new({ :callback => "http://sub.org/callback", 
                         :secret => "s3cret", 
                         :verify_token => "t0ken",
                         :id => "subscriber_id!" })
    res = Object.new
    mock(res).code.times(2).returns 200

    mock(HTTParty).post('http://sub.org/callback',
                        :follow_redirects => false,
                        :headers => { 
                                      "content-type" => "application/xml",
                                      "X-Hub-Signature" => "sha1=2bc05b80186ea76519dc1ae4871ef85a49ea17c9"
                                    },
                       :body => "content-foo").returns(res)
    t.post(s, 'application/xml', "content-foo").must_equal true
  end

  it "should POST and NOT sign data when POSTing and subscriber has NO secret" do
    t = build_topic_from_url("http://acme.org")
    s = Subscriber.new({ :callback => "http://sub.org/callback",
                         :verify_token => "t0ken",
                         :id => "subscriber_id!" })
    res = Object.new
    mock(res).code.times(2).returns 200

    mock(HTTParty).post('http://sub.org/callback',
                        :follow_redirects => false,
                        :headers => { 
                                      "content-type" => "application/xml"
                                    },
                       :body => "content-foo").returns(res)
    t.post(s, 'application/xml', "content-foo").must_equal true
  end

  it "should handle a case where callback returns non-2xx codes" do
    t = build_topic_from_url("http://acme.org")
    s = Subscriber.new({ :callback => "http://sub.org/callback",
                         :verify_token => "t0ken",
                         :id => "subscriber_id!" })
    res = Object.new
    mock(res).code.times(2).returns 404

    mock(HTTParty).post('http://sub.org/callback',
                        :follow_redirects => false,
                        :headers => { 
                                      "content-type" => "application/xml"
                                    },
                       :body => "content-foo").returns(res)
    t.post(s, 'application/xml', "content-foo").must_equal false
  end

end


 
describe Subscriber do
  it "should initialize" do
    s = Subscriber.new({ :callback => "http://sub.org/callback", 
                         :secret => "s3cret", 
                         :verify_token => "t0ken",
                         :id => "subscriber_id!" })
    s.callback.must_equal "http://sub.org/callback"
    s.secret.must_equal "s3cret"
    s.verify_token.must_equal "t0ken"
    s.id.must_equal "subscriber_id!"
  end
end


