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

    def validate!
      raise SleepError::AlreadyClockedIn if @user.sleep_records.clocked_in.exists?
    end
  end
end
