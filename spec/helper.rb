require 'simplecov'
SimpleCov.start if ENV["COVERAGE"]

require 'minitest/autorun'
require 'hubble'
require 'hubble/default'
require 'rr'

def file_content(file)
  File.read(File.expand_path("feeds/"+file, File.dirname(__FILE__)))
end


class MiniTest::Unit::TestCase
  include RR::Adapters::MiniTest
end

Hubble.log = Logger.new('/dev/null')
