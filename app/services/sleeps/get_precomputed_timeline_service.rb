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
      end_index = current_index + BATCH_SIZE - 1

      while collected_records.size < @per_page
        batch = fetch_batch(current_index, end_index)
        break if batch.empty?

        batch.each do |member, duration|
          record = process_record(member, duration)
          next unless record

          collected_records << record

          return [collected_records, current_index] if collected_records.size >= @per_page

          current_index += 1
        end

        current_index = end_index + 1
        end_index = current_index + BATCH_SIZE - 1

        break if stop_collecting_records?(batch.size, current_index)
      end

      [collected_records, current_index]
    end

    private

    def stop_collecting_records?(batch_size, current_index)
      batch_size < BATCH_SIZE || (current_index - @start_index) > 10_000
    end

    def fetch_batch(current_index, end_index)
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
        clocked_in_at: details["clocked_in_at"],
        clocked_out_at: details["clocked_out_at"],
        duration: duration.to_i,
        humanized_duration: ActiveSupport::Duration.build(duration.to_i).inspect,
        user: {
          id: details["user_id"],
          username: details["username"]
        }
      }
    end
  end
end
