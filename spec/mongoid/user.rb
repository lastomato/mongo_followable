class User
  include Mongoid::Document
  include Mongo::Followable
  include Mongo::Follower
end