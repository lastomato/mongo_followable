module Mongo
  module Followable
    module Followed
      extend ActiveSupport::Concern

      included do |base|
        if defined?(Mongoid)
          base.has_many :followers, :class_name => "Follow", :as => :followable, :dependent => :destroy
        elsif defined?(MongoMapper)
          base.many :followers, :class_name => "Follow", :as => :followable, :dependent => :destroy
        end
      end

      module ClassMethods

        # get certain model's followees of this type
        #
        # Example:
        #   >> @jim = User.new
        #   >> @ruby = Group.new
        #   >> @jim.save
        #   >> @ruby.save
        #
        #   >> @jim.follow(@ruby)
        #   >> User.followees_of(@jim)
        #   => [@ruby]
        #
        #   Arguments:
        #     model: instance of some followable model

        def followees_of(model)
          model.followees_by_type(self.name)
        end

        # 4 methods in this function
        #
        # Example:
        #   >> Group.with_max_followers
        #   => [@ruby]
        #   >> Group.with_max_followers_by_type('user')
        #   => [@ruby]

        ["max", "min"].each do |s|
          define_method(:"with_#{s}_followers") do
            follow_array = self.all.to_a.sort! { |a, b| a.followers_count <=> b.followers_count }
            num = follow_array[-1].followers_count
            follow_array.select { |c| c.followers_count == num }
          end

          define_method(:"with_#{s}_followers_by_type") do |*args|
            follow_array = self.all.to_a.sort! { |a, b| a.followers_count_by_type(args[0]) <=> b.followers_count_by_type(args[0]) }
            num = follow_array[-1].followers_count_by_type(args[0])
            follow_array.select { |c| c.followers_count_by_type(args[0]) == num }
          end
        end

        #def method_missing(name, *args)
        #  if name.to_s =~ /^with_(max|min)_followers$/i
        #    follow_array = self.all.to_a.sort! { |a, b| a.followers_count <=> b.followers_count }
        #    if $1 == "max"
        #      max = follow_array[-1].followers_count
        #      follow_array.select { |c| c.followers_count == max }
        #    elsif $1 == "min"
        #      min = follow_array[0].followers_count
        #      follow_array.select { |c| c.followers_count == min }
        #    end
        #  elsif name.to_s =~ /^with_(max|min)_followers_by_type$/i
        #    follow_array = self.all.to_a.sort! { |a, b| a.followers_count_by_type(args[0]) <=> b.followers_count_by_type(args[0]) }
        #    if $1 == "max"
        #      max = follow_array[-1].followers_count_by_type(args[0])
        #      follow_array.select { |c| c.followers_count_by_type(args[0]) == max }
        #    elsif $1 == "min"
        #      min = follow_array[0].followers_count
        #      follow_array.select { |c| c.followers_count_by_type(args[0]) == min }
        #    end
        #  else
        #    super
        #  end
        #end

      end

      # see if this model is followee of some model
      #
      # Example:
      #   >> @ruby.followee_of?(@jim)
      #   => true

      def followee_of?(model)
        0 < self.followers.by_model(model).limit(1).count * model.followees.by_model(self).limit(1).count
      end

      # return true if self is followed by some models
      #
      # Example:
      #   >> @ruby.followed?
      #   => true

      def followed?
        0 < self.followers.length
      end

      # get all the followers of this model, same with classmethod followers_of
      #
      # Example:
      #   >> @ruby.all_followers
      #   => [@jim]

      def all_followers(page = nil, per_page = nil)
        pipeline = [
          { '$project' =>
            { _id: 0,
              f_id: 1,
              followable_id: 1,
              followable_type: 1
            }
          },
          {
            '$match' => {
              'followable_id' => self.id,
              'followable_type' => self.class.name.split('::').last
            }
          }
        ]

        if page && per_page
          pipeline << { '$skip' => (page * per_page) }
          pipeline << { '$limit' => per_page }
        end

        pipeline << { '$project' => { f_id: 1 } }

        command = {
          aggregate: 'follows',
          pipeline: pipeline
        }

        if defined?(Mongoid)
          db = Mongoid.default_session
        elsif defined?(MongoMapper)
          db = MongoMapper.database
        end

        users_hash = db.command(command)['result']

        ids = users_hash.map {|e| e['f_id']}

        User.where(id: { '$in' => ids }).all.entries
      end

      def unfollowed(*models, &block)
        if block_given?
          models.delete_if { |model| !yield(model) }
        end

        models.each do |model|
          unless model == self or !self.followee_of?(model) or !model.follower_of?(self)
            model.followees.by_model(self).first.destroy
            self.followers.by_model(model).first.destroy
          end
        end
      end

      # unfollow all

      def unfollowed_all
        unfollowed(*self.all_followers)
      end

      # get all the followers of this model in certain type
      #
      # Example:
      #   >> @ruby.followers_by_type("user")
      #   => [@jim]

      def followers_by_type(type)
        rebuild_instances(self.followers.by_type(type))
      end

      # get the number of followers
      #
      # Example:
      #   >> @ruby.followers_count
      #   => 1

      def followers_count
        self.followers.count
      end

      # get the number of followers in certain type
      #
      # Example:
      #   >> @ruby.followers_count_by_type("user")
      #   => 1

      def followers_count_by_type(type)
        self.followers.by_type(type).count
      end

      # return if there is any common followers
      #
      # Example:
      #   >> @ruby.common_followees?(@python)
      #   => true

      def common_followers?(model)
        0 < (rebuild_instances(self.followers) & rebuild_instances(model.followers)).length
      end

      # get common followers with some model
      #
      # Example:
      #   >> @ruby.common_followers_with(@python)
      #   => [@jim]

      def common_followers_with(model)
        rebuild_instances(self.followers) & rebuild_instances(model.followers)
      end

      private
        def rebuild_instances(follows) #:nodoc:
          follows.group_by(&:f_type).inject([]) { |r, (k, v)| r += k.constantize.find(v.map(&:f_id)).to_a }
          #follow_list = []
          #follows.each do |follow|
          #  follow_list << follow.f_type.constantize.find(follow.f_id)
          #end
          #follow_list
        end
    end
  end
end
