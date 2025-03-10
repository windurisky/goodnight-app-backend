module Sleeps
  class ClockInService < ApplicationService
    def initialize(user:)
      @user = user
    end

    def call
      validate!

      SleepRecord.create!(user: @user, clocked_in_at: Time.current)
    end

    private

    def active_sleep_record
      @active_sleep_record ||= @user.sleep_records.clocked_in.first
    end

    def validate!
      raise SleepError::AlreadyClockedIn if active_sleep_record.present?
    end
  end
end
