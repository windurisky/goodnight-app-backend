class PushSleepRecordToPrecomputedTimelineJob < ApplicationJob
  queue_as :default

  def perform(sleep_record_id, user_id)
    Sleeps::PushSleepRecordToPrecomputedTimelineService.call(
      sleep_record_id: sleep_record_id,
      user_id: user_id
    )
  end
end
