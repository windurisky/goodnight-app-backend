module Sleeps
  class ClockOutService < ApplicationService
    def initialize(user:)
      @user = user
    end

    def call
      validate!

      sleep_record.clock_out!
      sleep_record
    end

    private

    def sleep_record
      @sleep_record ||= @user.sleep_records.clocked_in.first
    end

    def validate!
      raise SleepError::NotClockedIn if sleep_record.blank?
    end
  end
end
