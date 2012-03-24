module Mongo
  class FollowableError < StandardError
    def initialize(msg, info)
      @info = info
      super(msg)
    end
  end

  class NoMongoidOrMongoMapperError < FollowableError; end
end

if defined?(Mongoid) or defined?(MongoMapper)
  require File.join(File.dirname(__FILE__), "mongo_followable/core_ext/string")
  require File.join(File.dirname(__FILE__), "mongo_followable/followable")
  require File.join(File.dirname(__FILE__), "mongo_followable/follower")
  require File.join(File.dirname(__FILE__), "../app/models/follow")
end