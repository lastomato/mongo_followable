require "spec_helper"
require "benchmark"

users = []
1000.times { users << User.create! }
group = Group.create!

users.each { |u| u.follow(group) }

Benchmark.bmbm do |x|
  x.report("before") { group.followers }
end

RSpec.configure do |c|
  c.before(:all)  { DatabaseCleaner.strategy = :truncation }
  c.before(:each) { DatabaseCleaner.clean }
end
