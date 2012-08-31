class Group
  include Mongoid::Document
  include Mongo::Followable::Followed
  include Mongo::Followable::History
end