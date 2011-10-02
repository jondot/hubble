$: << '.'
$: << 'lib'

require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'resque/tasks'
require 'hubble'
require 'hubble/default'

Rake::TestTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.verbose = true
end
