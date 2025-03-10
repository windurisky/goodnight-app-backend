require "rails_helper"

RSpec.describe Sleeps::GetFollowingsSleepRecordsService do
  describe "#call" do
    let(:user) { create(:user) }
    let(:first_followed_user) { create(:user) }
    let(:second_followed_user) { create(:user) }
    let(:non_followed_user) { create(:user) }

    before do
      # Create follow relationships
      create(:follow, follower: user, followed: first_followed_user)
      create(:follow, follower: user, followed: second_followed_user)

      # Create sleep records for followed users
      create(:sleep_record,
             user: first_followed_user,
             state: "clocked_out",
             clocked_in_at: 2.days.ago,
             clocked_out_at: 2.days.ago + 8.hours,
             duration: 8.hours.to_i)

      create(:sleep_record,
             user: second_followed_user,
             state: "clocked_out",
             clocked_in_at: 3.days.ago,
             clocked_out_at: 3.days.ago + 6.hours,
             duration: 6.hours.to_i)

      # Create sleep record for non-followed user
      create(:sleep_record,
             user: non_followed_user,
             state: "clocked_out",
             clocked_in_at: 1.day.ago,
             clocked_out_at: 1.day.ago + 9.hours,
             duration: 9.hours.to_i)

      # Create in-progress record for first_followed_user
      create(:sleep_record,
             user: first_followed_user,
             state: "clocked_in",
             clocked_in_at: 6.hours.ago)

      # Create old record for second_followed_user
      create(:sleep_record,
             user: second_followed_user,
             state: "clocked_out",
             clocked_in_at: 2.weeks.ago,
             clocked_out_at: 2.weeks.ago + 7.hours,
             duration: 7.hours.to_i)
    end

    context "when user follows others with sleep records" do
      it "returns completed sleep records from the last week for followed users" do
        result = described_class.call(user: user)

        expect(result.size).to eq(2)

        # Should not include non-followed user's records
        expect(result.map(&:user_id)).not_to include(non_followed_user.id)

        # Should only include followed users' records
        expect(result.map(&:user_id)).to contain_exactly(first_followed_user.id, second_followed_user.id)

        # Should be ordered by duration (desc)
        expect(result.first.duration).to be > result.last.duration

        # Should not include in-progress records
        expect(result.map(&:state)).not_to include("clocked_in")

        # Should not include records older than a week
        expect(result.map(&:clocked_in_at)).not_to include(be < 1.week.ago)
      end
    end

    context "when user doesn't follow anyone" do
      let(:loner_user) { create(:user) }

      it "returns an empty array" do
        result = described_class.call(user: loner_user)
        expect(result).to be_empty
      end
    end

    context "when followed users have no sleep records" do
      let(:user_with_sleepless_friends) { create(:user) }
      let(:sleepless_friend) { create(:user) }

      before do
        create(:follow, follower: user_with_sleepless_friends, followed: sleepless_friend)
      end

      it "returns an empty array" do
        result = described_class.call(user: user_with_sleepless_friends)
        expect(result).to be_empty
      end
    end

    context "when followed users only have in-progress sleep records" do
      let(:user_with_insomniac_friends) { create(:user) }
      let(:insomniac_friend) { create(:user) }

      before do
        create(:follow, follower: user_with_insomniac_friends, followed: insomniac_friend)
        create(:sleep_record, user: insomniac_friend, state: "clocked_in")
      end

      it "returns an empty array" do
        result = described_class.call(user: user_with_insomniac_friends)
        expect(result).to be_empty
      end
    end

    context "when follow relationships are inactive" do
      let(:user_with_former_friends) { create(:user) }
      let(:former_friend) { create(:user) }

      before do
        create(:follow, follower: user_with_former_friends, followed: former_friend, active: false)

        create(:sleep_record,
               user: former_friend,
               state: "clocked_out",
               clocked_in_at: 1.day.ago,
               clocked_out_at: 1.day.ago + 8.hours,
               duration: 8.hours.to_i)
      end

      it "does not include records from inactive followings" do
        result = described_class.call(user: user_with_former_friends)
        expect(result).to be_empty
      end
    end
  end
end
