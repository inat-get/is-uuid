require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  minimum_coverage 50
end

require_relative '../lib/is-uuid'

require "rspec/core"
RSpec.configure do |config|
  config.order = :random
  config.filter_run_when_matching :focus
end
