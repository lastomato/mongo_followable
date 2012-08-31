module Mongo
  module Followable
    module History
      extend ActiveSupport::Concern

      included do |base|
        if base.include?(Mongo::Followable::Follower)
          if defined?(Mongoid)
            base.field :follow_history, :type => Array, :default => []
          elsif defined?(MongoMapper)
            base.key :follow_history, :type => Array, :default => []
          end
        end

        if base.include?(Mongo::Followable::Followed)
          if defined?(Mongoid)
            base.field :followed_history, :type => Array, :default => []
          elsif defined?(MongoMapper)
            base.key :followed_history, :type => Array, :default => []
          end
        end
      end

      module ClassMethods
 #       def clear_history!
 #         self.all.each { |m| m.unset(:follow_history) }
 #         self.all.each { |m| m.unset(:followed_history) }
 #       end
      end

      def clear_history!
        clear_follow_history!
        clear_followed_histroy!
      end

      def clear_follow_history!
        self.update_attribute(:follow_history, []) if has_follow_history?
      end

      def clear_followed_histroy!
        self.update_attribute(:followed_history, []) if has_followed_history?
      end

      def ever_follow
        rebuild(self.follow_history) if has_follow_history?
      end

      def ever_followed
        rebuild(self.followed_history) if has_followed_history?
      end

      def ever_follow?(model)
        self.follow_history.include?(model.class.name + "_" + model.id.to_s) if has_follow_history?
      end

      def ever_followed?(model)
        self.followed_history.include?(model.class.name + "_" + model.id.to_s) if has_followed_history?
      end

      private
        def has_follow_history?
          self.respond_to? :follow_history
        end

        def has_followed_history?
          self.respond_to? :followed_history
        end

        def rebuild(ary)
          ary.group_by { |x| x.split("_").first }.
              inject([]) { |n,(k,v)| n += k.constantize.
              find(v.map { |x| x.split("_").last}) }
        end
    end
  end
end