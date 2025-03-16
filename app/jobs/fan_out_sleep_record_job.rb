class FanOutSleepRecordJob < ApplicationJob
  queue_as :default

  def perform(sleep_record_id)
    sleep_record = SleepRecord.find_by(id: sleep_record_id) # ✅ Use argument, not instance variable
    raise SleepError::NotClockedOut unless sleep_record&.clocked_out?

    sleep_record.user.followers.find_in_batches(batch_size: 100) do |followers|
      followers.each do |follower|
        PushSleepRecordToPrecomputedTimelineJob.perform_later(sleep_record_id, follower.id)
      end
    end
  end
end
