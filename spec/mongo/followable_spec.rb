require 'spec_helper'

describe Mongo::Followable do

  describe User do

    let!(:u) { User.new }

    context "begins" do

      before do
      	u.save

        @v = User.new
        @v.save

        @w = User.new
        @w.save

        @g = Group.new
        @g.save
      end

      it "following a user" do
        u.follow(@v, @g)

        u.following?.should be_true
        @v.followed?.should be_true
        @g.followed?.should be_true

        u.follower_of?(@v).should be_true
        @v.followee_of?(u).should be_true

        u.all_followees.should == [@v, @g]
        @v.all_followers.should == [u]

        u.followees_by_type("user").should == [@v]
        @v.followers_by_type("user").should == [u]

        u.followees_count.should == 2
        @v.followers_count.should == 1

        u.followees_count_by_type("user").should == 1
        @v.followers_count_by_type("user").should == 1

        u.ever_follow.should =~ [@v, @g]
        @v.ever_followed.should == [u]

        u.common_followees?(@v).should be_false
        @v.common_followers?(u).should be_false
        u.common_followees_with(@v).should == []
        @v.common_followers_with(u).should == []

        User.with_max_followees.should == [u]
        User.with_max_followers.should == [@v]
        User.with_max_followees_by_type('user').should == [u]
        User.with_max_followers_by_type('user').should == [@v]
      end

      it "unfollowing" do
        u.unfollow_all

        u.follower_of?(@v).should be_false
        @v.followee_of?(u).should be_false

        u.all_followees.should == []
        @v.all_followers.should == []

        u.followees_by_type("user").should == []
        @v.followers_by_type("user").should == []

        u.followees_count.should == 0
        @v.followers_count.should == 0

        u.followees_count_by_type("user").should == 0
        @v.followers_count_by_type("user").should == 0
      end

      it "following a group" do
        u.follow(@g)

        u.follower_of?(@g).should be_true
        @g.followee_of?(u).should be_true

        u.all_followees.should == [@g]
        @g.all_followers.should == [u]

        u.followees_by_type("group").should == [@g]
        @g.followers_by_type("user").should == [u]

        u.followees_count.should == 1
        @g.followers_count.should == 1

        u.followees_count_by_type("group").should == 1
        @g.followers_count_by_type("user").should == 1

        u.follow(@v)

        u.ever_follow.should =~ [@g, @v]
        @g.ever_followed.should == [u]

        u.common_followees?(@v).should be_false
        @v.common_followers?(@g).should be_true
        u.common_followees_with(@v).should == []
        @v.common_followers_with(@g).should == [u]

        User.with_max_followees.should == [u]
        Group.with_max_followers.should == [@g]
        User.with_max_followees_by_type('group').should == [u]
        Group.with_max_followers_by_type('user').should == [@g]
      end

      it "unfollowing a group" do
        u.unfollow(@g)

        u.follower_of?(@g).should be_false
        @g.followee_of?(u).should be_false

        u.all_followees.should == []
        @g.all_followers.should == []

        u.followees_by_type("group").should == []
        @g.followers_by_type("group").should == []

        u.followees_count.should == 0
        @g.followers_count.should == 0

        u.followees_count_by_type("group").should == 0
        @g.followers_count_by_type("group").should == 0

      end
    end
  end

  describe Group do
    let!(:g) { Group.new }

    context "begins" do

      before do
      	g.save

        @v = User.new
        @w = User.new
        @u = User.new

        [@v, @w, @u].each { |u| u.save }
      end


      it "another way to unfollow a group" do
        @u.follow(g)
        @v.follow(g)
        @w.follow(g)

        g.all_followers.should =~ [@v,@u,@w]

        @w.follower_of?(g).should be_true
        g.followee_of?(@w).should be_true

        #g.unfollowed(@w)

        @u.follower_of?(g).should be_true
        g.followee_of?(@u).should be_true

        @v.follower_of?(g).should be_true
        g.followee_of?(@v).should be_true

        #g.all_followers.should =~ [@v,@u]

        g.unfollowed_all

        g.all_followers == []

      end

      it "another way to unfollow a group" do
        @u.follow(g)
        g.unfollowed(@u)
      end

      it "another way to unfollow a group" do

        g.all_followers.should == []
      end


    end
  end

  describe User do

    context "begins" do

      before do
        @u = User.new
        @u.save

        @v = User.new
        @v.save

        @w = User.new
        @w.save

        @g = Group.new
        @g.save
      end


      it "block test" do
        @u.follow(@v, @w, @g) {|m| m.class == User}

        @u.all_followees.should =~ [@v, @w]

      end

      it "block test unfollow" do
        @u.unfollow(@v, @w, @g) {|m| m.followee_of? @u}

        @u.all_followees.should == []
      end
    end
  end

  describe ChildUser do

    context "begins" do

      before do
        @u = ChildUser.new
        @u.save

        @w = User.new
        @w.save

        @g = Group.new
        @g.save
      end


      it "inherited model test" do
        @u.follow(@v, @w, @g) {|m| m.class == User}

        @u.all_followees.should == [@w]

        @u.followees_by_type("user") == [@w]

        @w.followers_by_type("child_user") == [@u]
        @w.followers_by_type("childUser") == [@u]
        @w.followers_by_type("ChildUser") == [@u]
      end
    end
  end
end
