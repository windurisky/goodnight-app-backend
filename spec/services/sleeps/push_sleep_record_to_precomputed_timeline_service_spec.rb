require "rails_helper"

RSpec.describe Sleeps::PushSleepRecordToPrecomputedTimelineService do
  describe "#call" do
    let!(:user) { create(:user) }
    let!(:sleep_owner) { create(:user) }
    let!(:sleep_record) do
      create(:sleep_record,
             user: sleep_owner,
             state: "clocked_out",
             clocked_in_at: 2.days.ago,
             clocked_out_at: 2.days.ago + 8.hours,
             duration: 8.hours.to_i)
    end

    context "when the sleep record and user are valid" do
      let!(:follow) { create(:follow, follower: user, followed: sleep_owner) }

      it "adds the sleep record to the user's precomputed timeline" do
        expect(RedisService).to receive(:add_to_sorted_set).with(
          "precomputed_timeline:#{user.id}",
          sleep_record.duration,
          "#{sleep_record.id}:#{sleep_record.visibility_expiry_time.to_i}"
        )

        expect(RedisService).to receive(:expire).with("precomputed_timeline:#{user.id}", 1.week)

        described_class.call(sleep_record_id: sleep_record.id, user_id: user.id)
      end
    end

    context "when the sleep record is not clocked out" do
      let!(:follow) { create(:follow, follower: user, followed: sleep_owner) }
      let!(:sleep_record) { create(:sleep_record, user: sleep_owner, state: "clocked_in") }

      it "raises a SleepError::NotClockedOut error" do
        expect(RedisService).not_to receive(:add_to_sorted_set)

        expect do
          described_class.call(sleep_record_id: sleep_record.id, user_id: user.id)
        end.to raise_error(SleepError::NotClockedOut)
      end
    end

    context "when the user does not exist" do
      it "raises a UserError::NotFound error" do
        expect(RedisService).not_to receive(:add_to_sorted_set)

        expect do
          described_class.call(sleep_record_id: sleep_record.id, user_id: SecureRandom.uuid)
        end.to raise_error(UserError::NotFound)
      end
    end

    context "when the user has unfollowed the sleep record owner" do
      it "raises a FollowError::AlreadyUnfollowed error" do
        expect(RedisService).not_to receive(:add_to_sorted_set)

        expect do
          described_class.call(sleep_record_id: sleep_record.id, user_id: user.id)
        end.to raise_error(FollowError::AlreadyUnfollowed)
      end
    end
  end
end
