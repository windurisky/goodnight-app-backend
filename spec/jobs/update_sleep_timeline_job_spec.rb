require "rails_helper"

RSpec.describe UpdateSleepTimelineJob, type: :job do
  describe "#perform" do
    let(:sleep_record_id) { SecureRandom.uuid } # ✅ No DB calls, just a fake UUID

    it "calls UpdateTimelineService with the correct sleep_record_id" do
      expect(Sleeps::UpdateTimelineService).to receive(:call).with(sleep_record_id: sleep_record_id)

      described_class.perform_now(sleep_record_id)      
    end
  end
end
