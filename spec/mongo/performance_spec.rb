require "benchmark"
require "rubygems"
require "bundler/setup"
require "mongoid"
require "../../lib/mongo_followable"
require "../../spec/mongoid/group"
require "../../spec/mongoid/user"

Mongoid.configure do |config|
  name = 'mongo_followable_test'
  host = 'localhost'
  config.master = Mongo::Connection.new.db(name)
  config.autocreate_indexes = true
end

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