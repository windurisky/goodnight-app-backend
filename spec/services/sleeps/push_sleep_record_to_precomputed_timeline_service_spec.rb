require "rails_helper"

RSpec.describe Sleeps::PushSleepRecordToPrecomputedTimelineService do
  describe "#call" do
    let(:user) { create(:user) }
    let(:sleep_owner) { create(:user) }
    let(:sleep_record) do
      create(:sleep_record,
             user: sleep_owner,
             state: "clocked_out",
             clocked_in_at: 2.days.ago,
             clocked_out_at: 2.days.ago + 8.hours,
             duration: 8.hours.to_i)
    end

    before do
      allow(RedisService).to receive(:add_to_sorted_set)
      allow(RedisService).to receive(:expire)
      allow(user).to receive(:follower_of?).and_return(true) # Simulate following
    end

    context "when the sleep record and user are valid" do
      it "adds the sleep record to the user's precomputed timeline" do
        described_class.call(sleep_record_id: sleep_record.id, user_id: user.id)

        cache_key = "precomputed_timeline:#{user.id}"
        member_name = "#{sleep_record.id}:#{sleep_record.visibility_expiry_time.to_i}"

        expect(RedisService).to have_received(:add_to_sorted_set).with(
          cache_key,
          sleep_record.duration,
          member_name
        )

        expect(RedisService).to have_received(:expire).with(cache_key, 1.week)
      end
    end

    context "when the sleep record is not clocked out" do
      let(:invalid_sleep_record) { create(:sleep_record, user: sleep_owner, state: "clocked_in") }

      it "raises a SleepError::NotClockedOut error" do
        expect do
          described_class.call(sleep_record_id: invalid_sleep_record.id, user_id: user.id)
        end.to raise_error(SleepError::NotClockedOut)

        expect(RedisService).not_to have_received(:add_to_sorted_set)
      end
    end

    context "when the user does not exist" do
      it "raises a UserError::NotFound error" do
        expect do
          described_class.call(sleep_record_id: sleep_record.id, user_id: SecureRandom.uuid)
        end.to raise_error(UserError::NotFound)

        expect(RedisService).not_to have_received(:add_to_sorted_set)
      end
    end

    context "when the user has unfollowed the sleep record owner" do
      before do
        allow(user).to receive(:follower_of?).and_return(false)
      end

      it "raises a FollowError::AlreadyUnfollowed error" do
        expect do
          described_class.call(sleep_record_id: sleep_record.id, user_id: user.id)
        end.to raise_error(FollowError::AlreadyUnfollowed)

        expect(RedisService).not_to have_received(:add_to_sorted_set)
      end
    end
  end
end
