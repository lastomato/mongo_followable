class ChildUser
  include MongoMapper::Document
  include Mongo::Followable
  include Mongo::Follower
end