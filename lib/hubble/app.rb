require 'sinatra'
require 'hubble'

module Hubble
  class App < Sinatra::Base

    post '/' do

      mode     = params[PSHB::MODE]
      callback = params[PSHB::CALLBACK]
      topic_url= params[PSHB::TOPIC]
      verify   = params[PSHB::VERIFY]
      vtoken   = params[PSHB::VTOKEN]
      secret   = params[PSHB::SECRET]
      url      = params[PSHB::URL]
      lease_secs  = params[PSHB::LEASE]

      unless ['subscribe', 'publish'].include? mode
        halt 400, "Only 'subscribe', 'publish' are allowed for #{PSHB::MODE}" 
      end

      if mode == 'subscribe'
        unless topic_url and callback and verify and ['sync', 'async'].include?(verify)
          halt 400, "Missing #{PSHB::CALLBACK}, #{PSHB::TOPIC}, or #{PSHB::VERIFY}"
        end

        topic = Topic.get_by_url(topic_url)
        halt 404, "No such topic '#{topic_url}'" unless topic

        sub = Subscriber.get_by_callback(callback)
        unless sub
          # sync only
          sub = Subscriber.create_and_validate callback, topic_url, secret, vtoken, lease_secs
          halt 409, "Cannot validate '#{callback}'" unless sub
        end

        halt 409, "The url '#{callback}' was not validated yet. Try later." unless sub.valid?
        topic.add_subscriber(sub)

      elsif mode == 'publish'
        halt 400, "missing #{PSHB::URL}" unless url && !url.empty?

        t = Topic.get_by_url(url) || Topic.create(url)
        t.ping_subscribers! if t
      end


      halt 204, 'no content'
    end

  end
end

