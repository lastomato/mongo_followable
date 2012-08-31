class Group
  include MongoMapper::Document
  include Mongo::Followable::Followed
  include Mongo::Followable::History
end