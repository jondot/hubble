require 'hubble/diffs/simple_feed_diff'
require 'hubble/profiles/redis_profile'

Hubble.configure do |c|
  c.profile = RedisProfile.new
  c.differ  = Hubble::SimpleFeedDiff.new
end

