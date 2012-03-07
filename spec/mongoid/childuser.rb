class ChildUser
  include Mongoid::Document
  include Mongo::Followable
  include Mongo::Follower
end