require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:following_relations).class_name("Follow").with_foreign_key("follower_id") }
    it { is_expected.to have_many(:follower_relations).class_name("Follow").with_foreign_key("followed_id") }
    it { is_expected.to have_many(:followings).through(:following_relations).source(:followed) }
    it { is_expected.to have_many(:followers).through(:follower_relations).source(:follower) }
  end

  describe "validations" do
    subject { build(:user, username: "unique_username", password: "password123") }

    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_uniqueness_of(:username).case_insensitive }
    it { is_expected.to validate_presence_of(:password).on(:create) }
    it { is_expected.to have_secure_password }
  end

  describe "uuid generation" do
    it "generates a UUID v7 on creation" do
      user = create(:user)
      expect(user.id).to be_present
      expect(user.id).to be_a_uuid(version: 7)
    end
  end

  describe "following methods" do
    let(:first_user) { create(:user) }
    let(:second_user) { create(:user) }

    it "follows another user" do
      create(:follow, follower: first_user, followed: second_user)

      expect(first_user.followings).to include(second_user)
      expect(second_user.followers).to include(first_user)
    end

    it "unfollows a user by setting active to false" do
      follow = create(:follow, follower: first_user, followed: second_user)
      follow.update(active: false)

      expect(first_user.followings).not_to include(second_user)
      expect(second_user.followers).not_to include(first_user)
    end

    it "does not include inactive follows" do
      create(:follow, follower: first_user, followed: second_user, active: false)

      expect(first_user.followings).not_to include(second_user)
      expect(second_user.followers).not_to include(first_user)
    end
  end

  describe "password security" do
    it "does not store the plain password" do
      password = "secure_password123"
      user = create(:user, password: password)

      expect(user.password_digest).not_to eq(password)
      expect(user.authenticate(password)).to eq(user)
    end

    it "authentication fails with wrong password" do
      user = create(:user, password: "correct_password")

      expect(user.authenticate("wrong_password")).to be_falsey
    end
  end
end
