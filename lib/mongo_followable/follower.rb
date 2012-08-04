module Mongo
  module Follower
    extend ActiveSupport::Concern

    included do |base|
      if defined?(Mongoid)
        if CONFIG[:authorization]
          base.field :cannot_follow, :type => Array, :default => []
        end

        if CONFIG[:history]
          base.field :follow_history, :type => Array, :default => []
        end

        base.has_many :followees, :class_name => "Follow", :as => :following, :dependent => :destroy
      elsif defined?(MongoMapper)
        if CONFIG[:authorization]
          base.key :cannot_follow, :type => Array, :default => []
        end

        if CONFIG[:history]
          base.key :follow_history, :type => Array, :default => []
        end

        base.many :followees, :class_name => "Follow", :as => :following, :dependent => :destroy
      end
    end

    module ClassMethods

      # get certain model's followers of this type
      #
      # Example:
      #   >> @jim = User.new
      #   >> @ruby = Group.new
      #   >> @jim.save
      #   >> @ruby.save
      #
      #   >> @jim.follow(@ruby)
      #   >> User.followers_of(@ruby)
      #   => [@jim]
      #
      #   Arguments:
      #     model: instance of some followable model

      def followers_of(model)
        model.followers_by_type(self.name)
      end

      # 4 methods in this function
      #
      # Example:
      #   >> User.with_max_followees
      #   => [@jim]
      #   >> User.with_max_followees_by_type('group')
      #   => [@jim]

      ["max", "min"].each do |s|
        define_method(:"with_#{s}_followees") do
          follow_array = self.all.to_a.sort! { |a, b| a.followees_count <=> b.followees_count }
          num = follow_array[-1].followees_count
          follow_array.select { |c| c.followees_count == num }
        end

        define_method(:"with_#{s}_followees_by_type") do |*args|
          follow_array = self.all.to_a.sort! { |a, b| a.followees_count_by_type(args[0]) <=> b.followees_count_by_type(args[0]) }
          num = follow_array[-1].followees_count_by_type(args[0])
          follow_array.select { |c| c.followees_count_by_type(args[0]) == num }
        end
      end

      #def method_missing(name, *args)
      #  if name.to_s =~ /^with_(max|min)_followees$/i
      #    follow_array = self.all.to_a.sort! { |a, b| a.followees_count <=> b.followees_count }
      #    if $1 == "max"
      #      max = follow_array[-1].followees_count
      #      follow_array.select { |c| c.followees_count == max }
      #    elsif $1 == "min"
      #      min = follow_array[0].followees_count
      #      follow_array.select { |c| c.followees_count == min }
      #    end
      #  elsif name.to_s =~ /^with_(max|min)_followees_by_type$/i
      #    follow_array = self.all.to_a.sort! { |a, b| a.followees_count_by_type(args[0]) <=> b.followees_count_by_type(args[0]) }
      #    if $1 == "max"
      #      max = follow_array[-1].followees_count_by_type(args[0])
      #      follow_array.select { |c| c.followees_count_by_type(args[0]) == max }
      #    elsif $1 == "min"
      #      min = follow_array[0].followees_count
      #      follow_array.select { |c| c.followees_count_by_type(args[0]) == min }
      #    end
      #  else
      #    super
      #  end
      #end

    end

    # set which mongoid user cannot follow
    #
    # Example:
    #   >> @jim.set_authorization('group', 'user')
    #   => true

    if CONFIG[:authorization]
      define_method(:set_authorization) do |*models|
        models.each do |model|
          self.cannot_follow << model.safe_capitalize
        end
        self.save
      end

      #unset which mongoid user cannot follow

      define_method(:unset_authorization) do |*models|
        models.each do |model|
          self.cannot_follow -= [model.safe_capitalize]
        end
        self.save
      end
    end

    # see if this model is follower of some model
    #
    # Example:
    #   >> @jim.follower_of?(@ruby)
    #   => true

    def follower_of?(model)
      0 < self.followees.by_model(model).limit(1).count * model.followers.by_model(self).limit(1).count
    end

    # return true if self is following some models
    #
    # Example:
    #   >> @jim.following?
    #   => true

    def following?
      0 < self.followees.length
    end

    # get all the followees of this model, same with classmethod followees_of
    #
    # Example:
    #   >> @jim.all_followees
    #   => [@ruby]

    def all_followees
      rebuild_instances(self.followees)
    end

    # get all the followees of this model in certain type
    #
    # Example:
    #   >> @ruby.followees_by_type("group")
    #   => [@ruby]

    def followees_by_type(type)
      rebuild_instances(self.followees.by_type(type))
    end

    # follow some model

    def follow(*models, &block)
      if block_given?
        models.delete_if { |model| !yield(model) }
      end

      models.each do |model|
        term = CONFIG[:authorization] ? (self.cannot_follow.include?(model.class.name) or model.cannot_followed.include?(self.class.name)) : false

        unless model == self or self.follower_of?(model) or model.followee_of?(self) or term
          model.followers.create!(:f_type => self.class.name, :f_id => self.id.to_s)
          self.followees.create!(:f_type => model.class.name, :f_id => model.id.to_s)

          if CONFIG[:history]
            model.followed_history << self.class.name + '_' + self.id.to_s
            self.follow_history << model.class.name + '_' + model.id.to_s
          end

          model.save
          self.save
        end
      end
    end

    # unfollow some model

    def unfollow(*models, &block)
      if block_given?
        models.delete_if { |model| !yield(model) }
      end

      models.each do |model|
        term = CONFIG[:authorization] ? (self.cannot_follow.include?(model.class.name) or model.cannot_followed.include?(self.class.name)) : false

        unless model == self or !self.follower_of?(model) or !model.followee_of?(self) or term
          model.followers.by_model(self).first.destroy
          self.followees.by_model(model).first.destroy
        end
      end
    end

    # unfollow all

    def unfollow_all
      unfollow(*self.all_followees)
    end

    # get the number of followees
    #
    # Example:
    #   >> @jim.followers_count
    #   => 1

    def followees_count
      self.followees.count
    end

    # get the number of followers in certain type
    #
    # Example:
    #   >> @ruby.followers_count_by_type("user")
    #   => 1

    def followees_count_by_type(type)
      self.followees.by_type(type).count
    end

    # see user's follow history
    #
    # Example:
    #   >> @jim.ever_follow
    #   => [@ruby]

    if CONFIG[:history]
      define_method(:ever_follow) do
        follow = []
        self.follow_history.each do |h|
          follow << h.split('_')[0].constantize.find(h.split('_')[1])
        end
        follow
      end
    end

    # return if there is any common followees
    #
    # Example:
    #   >> @jim.common_followees?(@tom)
    #   => true

    def common_followees?(model)
      0 < (rebuild_instances(self.followees) & rebuild_instances(model.followees)).length
    end

    # get common followees with some model
    #
    # Example:
    #   >> @jim.common_followees_with(@tom)
    #   => [@ruby]

    def common_followees_with(model)
      rebuild_instances(self.followees) & rebuild_instances(model.followees)
    end

    private
      def rebuild_instances(follows)
        follows.group_by { |f| f.f_type }.inject([]) { |s, (k, v)| s += k.constantize.find(v.map(&:f_id)).to_a }
      end
  end
end
