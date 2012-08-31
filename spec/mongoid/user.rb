class User
  include Mongoid::Document
  include Mongo::Followable::Followed
  include Mongo::Followable::Follower
  include Mongo::Followable::History
end