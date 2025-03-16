class UpdateSelfRecordJob < ApplicationJob
  queue_as :default

  def perform(sleep_record_id)
    Sleeps::UpdateSelfRecordService.call(sleep_record_id: sleep_record_id)
  end
end
