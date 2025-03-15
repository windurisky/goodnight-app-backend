class UpdateSleepTimelineJob < ApplicationJob
  queue_as :default

  def perform(sleep_record_id)
    sleep_record = SleepRecord.find_by(id: sleep_record_id)
    return unless sleep_record&.clocked_out?

    leaderboard_cache_key = "sleep_leaderboard:#{Time.current.strftime('%Y-%W')}"
    sleep_record_hash_key = "sleep_record:#{sleep_record.id}"

    # Store in Redis sorted set (sorted by duration)
    RedisService.add_to_sorted_set(
      leaderboard_cache_key,
      sleep_record.duration,
      sleep_record.id
    )

    user = sleep_record.user

    # Store detailed metadata in Redis Hash
    RedisService.set_hash_field(sleep_record_hash_key, "user_id", user.id)
    RedisService.set_hash_field(sleep_record_hash_key, "username", user.username)
    RedisService.set_hash_field(sleep_record_hash_key, "clocked_in_at", sleep_record.clocked_in_at.iso8601)
    RedisService.set_hash_field(sleep_record_hash_key, "clocked_out_at", sleep_record.clocked_out_at.iso8601)
    RedisService.set_hash_field(sleep_record_hash_key, "duration", sleep_record.duration)

    # Auto-expire the record in 7 days
    RedisService.expire("sleep_record:#{sleep_record.id}", 7.days.to_i)
  end
end
