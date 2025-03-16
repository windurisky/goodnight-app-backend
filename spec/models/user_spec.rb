require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:following_relations).class_name("Follow").with_foreign_key("follower_id") }
    it { is_expected.to have_many(:follower_relations).class_name("Follow").with_foreign_key("followed_id") }
    it { is_expected.to have_many(:followings).through(:following_relations).source(:followed) }
    it { is_expected.to have_many(:followers).through(:follower_relations).source(:follower) }
    it { is_expected.to have_many(:sleep_records) }
  end

  describe "validations" do
    subject { build(:user, username: "unique_username", password: "password123") }

    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_uniqueness_of(:username).case_insensitive }
    it { is_expected.to validate_presence_of(:password).on(:create) }
    it { is_expected.to have_secure_password }

    context "when updating a user" do
      let(:existing_user) { create(:user, password: "existing_password") }

      it "does not require password to be present" do
        expect(existing_user.update(username: "new_username")).to be_truthy
      end
    end
  end

  describe "uuid generation" do
    it "generates a UUID v7 on creation" do
      user = create(:user)
      expect(user.id).to be_present
      expect(user.id).to be_a_uuid(version: 7)
    end
  end

  describe "#following?" do
    let(:first_user) { create(:user) }
    let(:second_user) { create(:user) }

    context "when following a user" do
      before { create(:follow, follower: first_user, followed: second_user) }

      it "returns true" do
        expect(first_user.following?(second_user)).to be true
      end
    end

    context "when not following a user" do
      it "returns false" do
        expect(first_user.following?(second_user)).to be false
      end
    end

    context "when the follow relationship is inactive" do
      before { create(:follow, follower: first_user, followed: second_user, active: false) }

      it "returns false" do
        expect(first_user.following?(second_user)).to be false
      end
    end
  end

  describe "#follower_of?" do
    let(:first_user) { create(:user) }
    let(:second_user) { create(:user) }

    context "when followed by another user" do
      before { create(:follow, follower: first_user, followed: second_user) }

      it "returns true" do
        expect(first_user.follower_of?(second_user)).to be true
      end
    end

    context "when not followed by another user" do
      it "returns false" do
        expect(first_user.follower_of?(second_user)).to be false
      end
    end

    context "when the follow relationship is inactive" do
      before { create(:follow, follower: second_user, followed: first_user, active: false) }

      it "returns false" do
        expect(first_user.follower_of?(second_user)).to be false
      end
    end
  end

  describe "following behavior" do
    let(:first_user) { create(:user) }
    let(:second_user) { create(:user) }

    it "allows a user to follow another" do
      create(:follow, follower: first_user, followed: second_user)

      expect(first_user.followings).to include(second_user)
      expect(second_user.followers).to include(first_user)
    end

    it "removes a user from followings when follow is inactive" do
      follow = create(:follow, follower: first_user, followed: second_user)
      follow.update(active: false)

      expect(first_user.followings).not_to include(second_user)
      expect(second_user.followers).not_to include(first_user)
    end

    it "does not list inactive follows" do
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

    it "fails authentication with an incorrect password" do
      user = create(:user, password: "correct_password")

      expect(user.authenticate("wrong_password")).to be_falsey
    end
  end
end
