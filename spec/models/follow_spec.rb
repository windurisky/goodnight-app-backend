require "rails_helper"

RSpec.describe Follow, type: :model do
  let(:first_user) { create(:user) }
  let(:second_user) { create(:user) }
  let(:third_user) { create(:user) }

  describe "associations" do
    it { is_expected.to belong_to(:follower).class_name("User") }
    it { is_expected.to belong_to(:followed).class_name("User") }
  end

  describe "validations" do
    it "prevents following yourself" do
      follow = build(:follow, follower: first_user, followed: first_user)
      expect(follow).not_to be_valid
      expect(follow.errors[:followed_id]).to include("You cannot follow yourself")
    end
  end

  describe "uuid generation" do
    it "generates a UUID v7 on creation" do
      follow = create(:follow, follower: first_user, followed: second_user)
      expect(follow.id).to be_present
      expect(follow.id).to be_a_uuid(version: 7)
    end
  end

  describe "uniqueness" do
    it "prevents duplicate follow relationships" do
      create(:follow, follower: first_user, followed: second_user)

      expect do
        create(:follow, follower: first_user, followed: second_user)
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "active scope" do
    it "only returns active follows" do
      active_follow = create(:follow, follower: first_user, followed: second_user)
      inactive_follow = create(:follow, follower: first_user, followed: third_user, active: false)

      expect(described_class.active).to include(active_follow)
      expect(described_class.active).not_to include(inactive_follow)
    end
  end

  describe "following behavior" do
    it "allows deactivating a follow relationship" do
      follow = create(:follow, follower: first_user, followed: second_user)
      follow.update(active: false)

      expect(follow.reload).not_to be_active
    end

    it "prevents creating a new follow after deactivating an existing one" do
      # Create and deactivate a follow
      follow = create(:follow, follower: first_user, followed: second_user)
      follow.update(active: false)

      # Try to create a new follow - should still fail due to unique index
      expect do
        create(:follow, follower: first_user, followed: second_user)
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
