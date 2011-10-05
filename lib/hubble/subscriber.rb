require 'httparty'  # for subscriber validation (use in subscriber)
require 'digest/md5' 
require 'simple_uuid'
require 'hmac-sha1'
require 'hubble'

module Hubble
  class Subscriber
    attr_accessor :callback, :secret, :id, :verify_token

    def self.profile
      Hubble.profile
    end

    def self.log
      Hubble.log
    end

    def initialize(h, is_new=true)
      @callback = h[:callback]
      @secret   = h[:secret]
      @id       = h[:id]
      @verify_token = h[:verify_token]
      @valid    = h[:valid] || false
    end

    def valid?
      @valid
    end

    def self.get_by_callback(callback)
      profile.get_subscriber(callback)
    end


    def self.create_and_validate(callback, url, secret, vtoken, lease_secs)
      # synchronous http call to validate
      challenge = SimpleUUID::UUID.new.to_i.to_s
      query = {
                PSHB::MODE  => "subscribe",
                PSHB::TOPIC => url,
                PSHB::CHALLENGE => challenge,
                PSHB::LEASE     => lease_secs || LEASE_SECONDS
              }

      query.merge!({PSHB::VTOKEN => vtoken}) if vtoken

      res = HTTParty.get(callback, :follow_redirects=>false, :query=> query)

      # only accept 2xx family.
      return nil unless res.code >= 200 && res.code < 300
      # response must be our challenge
      return nil unless res.body == challenge

      # go ahead
      # no invalid yet because we're only doing sync!.
      # which means, if the sub was added it is valid.
      log.info("New subscriber (valid): #{callback}")
      profile.create_subscriber(
        Subscriber.new( { :callback => callback,
                          :secret   => secret,
                          :vtoken   => vtoken,
                          :valid => true }))

    end
  end
end
