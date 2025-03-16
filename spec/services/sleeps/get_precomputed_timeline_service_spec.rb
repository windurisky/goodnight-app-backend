require "rails_helper"

RSpec.describe Sleeps::GetPrecomputedTimelineService do
  describe "#call" do
    let(:user) { create(:user) }
    let(:cache_key) { "precomputed_timeline:#{user.id}" }
    let(:valid_sleep_record_id) { SecureRandom.uuid }
    let(:expired_sleep_record_id) { SecureRandom.uuid }
    let(:future_timestamp) { 1.day.from_now.to_i }
    let(:expired_timestamp) { 1.day.ago.to_i }

    let(:valid_redis_entry) { [["#{valid_sleep_record_id}:#{future_timestamp}", 28_800]] }
    let(:expired_redis_entry) do
      [["#{expired_sleep_record_id}:#{expired_timestamp}", 28_800],
       ["#{valid_sleep_record_id}:#{future_timestamp}", 28_800]]
    end
    let(:empty_redis_entry) { [] }

    context "when user is not found" do
      it "raises UserError::NotFound" do
        expect do
          described_class.call(user: nil, start_index: 0, per_page: 10)
        end.to raise_error(UserError::NotFound)
      end
    end

    context "when there are valid sleep records in Redis" do
      before do
        allow(RedisService).to receive(:reverse_range_from_sorted_set)
          .with(cache_key, 0, 99, with_scores: true)
          .and_return(valid_redis_entry)
        allow(RedisService).to receive_messages(
          get_hash_all: {
            "user_id" => user.id.to_s,
            "username" => "test_user",
            "clocked_in_at" => "2025-03-10T22:00:00Z",
            "clocked_out_at" => "2025-03-11T06:00:00Z"
          }
        )
      end

      it "returns valid sleep records and correct last index" do
        records, last_index = described_class.call(user: user, start_index: 0, per_page: 1)

        expect(records.size).to eq(1)
        expect(records.first[:id]).to eq(valid_sleep_record_id)
        expect(records.first[:user_id]).to eq(user.id.to_s)

        expect(last_index).to eq(0) # Instead of hardcoded `1`, use correct pagination logic
      end
    end

    context "when Redis contains expired records" do
      before do
        allow(RedisService).to receive(:reverse_range_from_sorted_set)
          .with(cache_key, 0, 99, with_scores: true)
          .and_return(expired_redis_entry)
      end

      it "skips expired records and returns correct last index" do
        records, last_index = described_class.call(user: user, start_index: 0, per_page: 1)

        expect(records).to be_empty

        # ✅ Ensure last_index is updated correctly even when all records are skipped
        expect(last_index).to eq(100) # Because we scanned 100 records but found none
      end
    end

    context "when Redis data is missing" do
      before do
        allow(RedisService).to receive(:reverse_range_from_sorted_set)
          .with(cache_key, 0, 99, with_scores: true)
          .and_return(valid_redis_entry)
        allow(RedisService).to receive_messages(get_hash_all: {})
      end

      it "skips records with missing metadata and returns correct last index" do
        records, last_index = described_class.call(user: user, start_index: 0, per_page: 1)

        expect(records).to be_empty
        expect(last_index).to eq(100)
      end
    end

    context "when there are fewer records than requested per_page" do
      before do
        allow(RedisService).to receive(:reverse_range_from_sorted_set)
          .with(cache_key, 0, 99, with_scores: true)
          .and_return(valid_redis_entry)

        allow(RedisService).to receive_messages(
          get_hash_all: {
            "user_id" => user.id.to_s,
            "username" => "test_user",
            "clocked_in_at" => "2025-03-10T22:00:00Z",
            "clocked_out_at" => "2025-03-11T06:00:00Z"
          }
        )
      end

      it "returns available records and stops at correct last index" do
        records, last_index = described_class.call(user: user, start_index: 0, per_page: 5)

        expect(records.size).to eq(1) # Only 1 valid record available

        expect(last_index).to eq(100)
      end
    end

    context "when there are no sleep records in Redis" do
      it "returns an empty array and correct last index" do
        records, last_index = described_class.call(user: user, start_index: 0, per_page: 10)

        expect(records).to eq([])
        expect(last_index).to eq(0)
      end
    end
  end
end
