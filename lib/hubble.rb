require 'hubble/topic'
require 'hubble/subscriber'
require 'forwardable'

module Hubble
  LEASE_SECONDS = 3600

  module PSHB
    MODE = 'hub.mode'
    CALLBACK = 'hub.callback'
    TOPIC    = 'hub.topic'
    VERIFY   = 'hub.verify'
    VTOKEN   = 'hub.verify_token'
    SECRET   = 'hub.secret'
    URL      = 'hub.url'
    LEASE    = 'hub.lease_seconds'
    CHALLENGE = 'hub.challenge'
  end

  extend SingleForwardable
  extend self

  attr_accessor :profile
  def_delegator :profile, :connection=

  attr_accessor :differ, :log


  def configure(&block)
    block.call(self)
  end
end
