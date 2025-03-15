require "rails_helper"

RSpec.describe Sleeps::UpdateTimelineService do
  describe "#call" do
    let(:user) { create(:user) }
    let(:valid_sleep_record) do
      create(:sleep_record,
             user: user,
             state: "clocked_out",
             clocked_in_at: 2.days.ago,
             clocked_out_at: 2.days.ago + 8.hours,
             duration: 8.hours.to_i)
    end
    let(:in_progress_sleep_record) do
      create(:sleep_record,
             user: user,
             state: "clocked_in",
             clocked_in_at: 6.hours.ago)
    end
    let(:expired_sleep_record) do
      create(:sleep_record,
             user: user,
             state: "clocked_out",
             clocked_in_at: 10.days.ago,
             clocked_out_at: 10.days.ago + 7.hours,
             duration: 7.hours.to_i)
    end

    context "when the sleep record is valid" do
      it "stores the sleep record in Redis" do
        leaderboard_cache_key = "sleep_records_by_user_id:#{user.id}"
        sleep_record_hash_key = "sleep_record_by_id:#{valid_sleep_record.id}"
        member_value = "#{valid_sleep_record.id}:#{(valid_sleep_record.clocked_in_at + 7.days).to_i}"

        expect(RedisService).to receive(:add_to_sorted_set).with(
          leaderboard_cache_key,
          valid_sleep_record.duration,
          member_value
        )

        expect(RedisService).to receive(:set_hash_field).with(sleep_record_hash_key, "user_id", user.id)
        expect(RedisService).to receive(:set_hash_field).with(sleep_record_hash_key, "username", user.username)
        expect(RedisService).to receive(:set_hash_field).with(sleep_record_hash_key, "clocked_in_at", valid_sleep_record.clocked_in_at.iso8601)
        expect(RedisService).to receive(:set_hash_field).with(sleep_record_hash_key, "clocked_out_at", valid_sleep_record.clocked_out_at.iso8601)
        expect(RedisService).to receive(:set_hash_field).with(sleep_record_hash_key, "duration", valid_sleep_record.duration)
        expect(RedisService).to receive(:expire).with(sleep_record_hash_key, (valid_sleep_record.clocked_in_at + 7.days - Time.current).to_i)

        described_class.call(sleep_record_id: valid_sleep_record.id)
      end
    end

    context "when the sleep record is not clocked out" do
      it "raises a SleepError::NotClockedOut error" do
        expect {
          described_class.call(sleep_record_id: in_progress_sleep_record.id)
        }.to raise_error(SleepError::NotClockedOut)
      end
    end

    context "when the sleep record is expired" do
      it "does not store the sleep record in Redis" do
        expect(RedisService).not_to receive(:add_to_sorted_set)
        expect(RedisService).not_to receive(:set_hash_field)
        expect(RedisService).not_to receive(:expire)

        described_class.call(sleep_record_id: expired_sleep_record.id)
      end
    end
  end
end
