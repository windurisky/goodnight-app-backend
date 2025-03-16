module Sleeps
  class PushSleepRecordToPrecomputedTimelineService < ApplicationService
    def initialize(sleep_record_id:, user_id:)
      @sleep_record_id = sleep_record_id
      @user_id = user_id
    end

    def call
      validate!

      cache_key = "precomputed_timeline:#{user_id}"
      member_name = "#{sleep_record.id}:#{sleep_record.visibility_expiry_time.to_i}"

      RedisService.add_to_sorted_set(
        cache_key,
        sleep_record.duration,
        member_name
      )

      RedisService.expire(cache_key, 1.week)

      sleep_record
    end

    private

    def validate!
      raise SleepError::NotClockedOut unless sleep_record&.clocked_out?
      raise UserError::NotFound if user.blank?
      raise FollowError::AlreadyUnfollowed unless user.follower_of?(sleep_record.user)
    end

    def sleep_record
      @sleep_record ||= SleepRecord.find_by(id: @sleep_record_id)
    end

    def user
      @user ||= User.find_by(id: @user_id)
    end
  end
end
