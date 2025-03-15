module Sleeps
  class UpdateTimelineService < ApplicationService
    def initialize(sleep_record_id:)
      @sleep_record_id = sleep_record_id
    end

    def call
      validate!

      return if ttl_seconds <= 0

      set_cache_data
    end

    private

    def set_cache_data
      set_sorted_set_cache
      set_hash_cache
    end

    def set_sorted_set_cache
      leaderboard_cache_key = "sleep_records_by_user_id:#{sleep_record.user.id}"

      # Store in Redis sorted set (sorted by duration)
      RedisService.add_to_sorted_set(
        leaderboard_cache_key,
        sleep_record.duration,
        "#{sleep_record.id}:#{data_expiry_time.to_i}"
      )
    end

    def set_hash_cache
      sleep_record_hash_key = "sleep_record_by_id:#{sleep_record.id}"

      # Store detailed metadata in Redis Hash
      RedisService.set_hash_field(sleep_record_hash_key, "user_id", sleep_record.user.id)
      RedisService.set_hash_field(sleep_record_hash_key, "username", sleep_record.user.username)
      RedisService.set_hash_field(sleep_record_hash_key, "clocked_in_at", sleep_record.clocked_in_at.iso8601)
      RedisService.set_hash_field(sleep_record_hash_key, "clocked_out_at", sleep_record.clocked_out_at.iso8601)
      RedisService.set_hash_field(sleep_record_hash_key, "duration", sleep_record.duration)

      # Auto-expire the hash in 7 days
      RedisService.expire(sleep_record_hash_key, ttl_seconds)
    end

    def data_expiry_time
      sleep_record.clocked_in_at + 7.days
    end

    def ttl_seconds
      (data_expiry_time - Time.current).to_i
    end

    def sleep_record
      @sleep_record ||= SleepRecord.find_by(id: @sleep_record_id)
    end

    def validate!
      raise SleepError::NotClockedOut unless sleep_record&.clocked_out?
    end
  end
end
