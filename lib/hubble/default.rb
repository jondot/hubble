require 'hubble/diffs/simple_feed_diff'
require 'hubble/profiles/redis_profile'
require 'logger'

Hubble.configure do |c|
  c.profile = RedisProfile.new
  c.differ  = Hubble::SimpleFeedDiff.new
  c.log     = Logger.new(STDOUT)
end

