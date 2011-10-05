require 'digest/md5' #for topic

#
# topic
# - url
# - id = md5(url)
# topic:32723dfba2b23af91eed31c  HSH  url => 'http://acme.org'
#
module Hubble
  class Topic
    attr_accessor :id, :url
    
    def self.profile
      Hubble.profile
    end

    def self.differ
      Hubble.differ
    end

    def self.log
      Hubble.log
    end

    def initialize(h)
      @url = h[:url]
      @id  = h[:id]
    end

    def self.get_by_url(topic_url)
      profile.get_topic(topic_url)
    end

    def self.create(topic_url)
      self.class.log.info("New topic: #{url}")
      t = Topic.new({:url => topic_url})
      profile.save_topic(t)
    end

    def add_subscriber(sub)
      self.class.log.info("Subscribing #{sub.callback} to #{self.url}")
      self.class.profile.subscribe(self, sub)
    end

    def publish
      subs = self.class.profile.get_subscribers(self)

      return if subs.empty?

      res = fetch()
      return unless res

      content_type = res.content_type
      content_body = res.body
      last_content, diff_content = self.class.differ.diff(self.class.profile.get_last_content(self.id), 
                                                          content_body,
                                                          content_type)

      return nil if diff_content.nil? # cant diff (content not suitable)
      self.class.profile.set_last_content(self.id, last_content)

      self.class.log.info("POSTing #{subs.size} subscribers")
      subs.each{ |s| post(s, res.content_type, diff_content) }
    end


    def post(subscriber, content_type, diff_content)
      headers = {
        'content-type' => content_type
      }

      if(subscriber.secret)
        headers.merge!({'X-Hub-Signature' => 
                       "sha1=#{HMAC::SHA1.hexdigest(subscriber.secret, diff_content)}" })
      end
      

      res = HTTParty.post(subscriber.callback, 
                          :follow_redirects => false, 
                          :headers => headers,
                          :body => diff_content)
      res.code >=200 && res.code < 300
    end

    def fetch()
      res = HTTParty.get(url)
      log.info("Fetched #{url}")

      #figure out if this content is valid.
      return nil unless ['application/atom+xml', 'application/rss+xml'].include? res.content_type
      return nil unless res.code >= 200 && res.code < 300
      res
    end

    def ping_subscribers!
      self.class.profile.execute(self, :publish)
    end

    def self.id_from_url(topic_url)
      Digest::MD5.hexdigest(topic_url)
    end

  end

end
