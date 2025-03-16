require "rails_helper"

RSpec.describe UpdateSelfRecordJob, type: :job do
  describe "#perform" do
    let(:sleep_record_id) { SecureRandom.uuid } # ✅ No DB calls, just a fake UUID

    it "calls UpdateSelfRecordService with the correct sleep_record_id" do
      expect(Sleeps::UpdateSelfRecordService).to receive(:call).with(sleep_record_id: sleep_record_id)

      described_class.perform_now(sleep_record_id)
    end
  end
end
