module Sleeps
  class UpdateTimelineService < ApplicationService
    def initialize(sleep_record_id:)
      @sleep_record_id = sleep_record_id
    end

    def call
      validate!

      set_cache_data
    end

    private

    def set_cache_data
      return if Time.current > data_expiry_time

      user = sleep_record.user
      leaderboard_cache_key = "sleep_records_by_user_id:#{user.id}"
      sleep_record_hash_key = "sleep_record_by_id:#{sleep_record.id}"

      # Store in Redis sorted set (sorted by duration)
      RedisService.add_to_sorted_set(
        leaderboard_cache_key,
        sleep_record.duration,
        "#{sleep_record.id}:#{data_expiry_time.to_i}"
      )

      # Store detailed metadata in Redis Hash
      RedisService.set_hash_field(sleep_record_hash_key, "user_id", user.id)
      RedisService.set_hash_field(sleep_record_hash_key, "username", user.username)
      RedisService.set_hash_field(sleep_record_hash_key, "clocked_in_at", sleep_record.clocked_in_at.iso8601)
      RedisService.set_hash_field(sleep_record_hash_key, "clocked_out_at", sleep_record.clocked_out_at.iso8601)
      RedisService.set_hash_field(sleep_record_hash_key, "duration", sleep_record.duration)

      # Auto-expire the hash in 7 days
      RedisService.expire("sleep_record:#{sleep_record.id}", data_expiry_time.to_i)
    end

    def data_expiry_time
      sleep_record.clocked_in_at + 7.days
    end

    def sleep_record
      @sleep_record ||= SleepRecord.find_by(id: @sleep_record_id)
    end

    def validate!
      raise SleepError::NotClockedOut unless sleep_record&.clocked_out?
    end
  end
end
