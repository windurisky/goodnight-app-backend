module Sleeps
  class GetPrecomputedTimelineService < ApplicationService
    BATCH_SIZE = 100

    def initialize(user:, start_index: 0, per_page: 10)
      @user = user
      @start_index = start_index
      @per_page = per_page
    end

    def call
      raise UserError::NotFound if @user.blank?

      collected_records = []
      current_index = @start_index

      while collected_records.size < @per_page
        batch = fetch_batch(current_index)
        break if batch.empty?

        batch.each do |member, duration|
          record = process_record(member, duration)
          next unless record

          collected_records << record

          return [collected_records, current_index] if collected_records.size >= @per_page

          current_index += 1
        end
      end

      [collected_records, current_index]
    end

    private

    def fetch_batch(current_index)
      end_index = current_index + BATCH_SIZE - 1
      RedisService.reverse_range_from_sorted_set(cache_key, current_index, end_index, with_scores: true)
    end

    def cache_key
      @cache_key ||= "precomputed_timeline:#{@user.id}"
    end

    def process_record(member, duration)
      sleep_record_id, expires_at = member.split(":")
      return if expires_at.to_i <= Time.current.to_i

      details = RedisService.get_hash_all("sleep_record_by_id:#{sleep_record_id}")
      return if details.empty?

      {
        id: sleep_record_id,
        user_id: details["user_id"],
        username: details["username"],
        clocked_in_at: details["clocked_in_at"],
        clocked_out_at: details["clocked_out_at"],
        duration: duration.to_i
      }
    end
  end
end
