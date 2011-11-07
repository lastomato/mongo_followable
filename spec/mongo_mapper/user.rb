class User
  include MongoMapper::Document
  include Mongo::Followable
  include Mongo::Follower
end