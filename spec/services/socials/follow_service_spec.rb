require "rails_helper"

RSpec.describe Socials::FollowService do
  describe "#call" do
    let(:user) { create(:user) }
    let(:target_user) { create(:user) }

    context "when params are valid" do
      it "creates a new follow relationship" do
        expect do
          described_class.call(user: user, target_user_id: target_user.id)
        end.to change(Follow, :count).by(1)

        follow = Follow.last
        expect(follow.follower).to eq(user)
        expect(follow.followed).to eq(target_user)
        expect(follow.active).to be true
      end
    end

    context "when target user does not exist" do
      it "raises a UserError::NotFound" do
        expect do
          described_class.call(user: user, target_user_id: "non-existent-id")
        end.to raise_error(UserError::NotFound)
      end
    end

    context "when already following the user" do
      before do
        create(:follow, follower: user, followed: target_user, active: true)
      end

      it "raises a FollowError::AlreadyFollowed" do
        expect do
          described_class.call(user: user, target_user_id: target_user.id)
        end.to raise_error(FollowError::AlreadyFollowed)
      end
    end

    context "when reactivating an inactive follow" do
      let!(:inactive_follow) { create(:follow, follower: user, followed: target_user, active: false) }

      it "reactivates the existing follow relationship" do
        expect do
          described_class.call(user: user, target_user_id: target_user.id)
        end.not_to change(Follow, :count)

        expect(inactive_follow.reload.active).to be true
      end
    end

    context "when trying to follow yourself" do
      it "raises an ActiveRecord::RecordInvalid error" do
        expect do
          described_class.call(user: user, target_user_id: user.id)
        end.to raise_error(ActiveRecord::RecordInvalid, /You cannot follow yourself/)
      end
    end
  end
end
