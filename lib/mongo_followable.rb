if defined?(Mongoid) or defined?(MongoMapper)
  require File.join(File.dirname(__FILE__), "mongo_followable/core_ext/string")
  require File.join(File.dirname(__FILE__), "mongo_followable/followed")
  require File.join(File.dirname(__FILE__), "mongo_followable/follower")
  require File.join(File.dirname(__FILE__), "../app/models/follow")
end