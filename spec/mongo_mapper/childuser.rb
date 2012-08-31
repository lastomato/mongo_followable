class ChildUser
  include MongoMapper::Document
  include Mongo::Followable::Followed
  include Mongo::Followable::Follower
  include Mongo::Followable::History
end