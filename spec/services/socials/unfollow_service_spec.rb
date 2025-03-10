require "rails_helper"

RSpec.describe Socials::UnfollowService do
  describe "#call" do
    let(:user) { create(:user) }
    let(:target_user) { create(:user) }

    context "when target user is being followed" do
      let!(:active_follow) { create(:follow, follower: user, followed: target_user, active: true) }

      it "deactivates the follow relationship" do
        expect do
          described_class.call(user: user, target_user_id: target_user.id)
        end.not_to change(Follow, :count)

        expect(active_follow.reload.active).to be false
      end

      it "returns the updated follow object" do
        result = described_class.call(user: user, target_user_id: target_user.id)
        expect(result).to eq(active_follow.reload)
        expect(result.active).to be false
      end
    end

    context "when target user does not exist" do
      it "raises a UserError::NotFound" do
        expect do
          described_class.call(user: user, target_user_id: "non-existent-id")
        end.to raise_error(UserError::NotFound)
      end
    end

    context "when not following the user" do
      it "raises a FollowError::AlreadyUnfollowed" do
        expect do
          described_class.call(user: user, target_user_id: target_user.id)
        end.to raise_error(FollowError::AlreadyUnfollowed)
      end
    end

    context "when follow relationship exists but is already inactive" do
      before do
        create(:follow, follower: user, followed: target_user, active: false)
      end

      it "raises a FollowError::AlreadyUnfollowed" do
        expect do
          described_class.call(user: user, target_user_id: target_user.id)
        end.to raise_error(FollowError::AlreadyUnfollowed)
      end
    end
  end
end
