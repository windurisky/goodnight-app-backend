require "rails_helper"

RSpec.describe Sleeps::ClockOutService do
  describe "#call" do
    let(:user) { create(:user) }

    context "when user has an active sleep record" do
      let!(:sleep_record) { create(:sleep_record, user: user, clocked_in_at: 8.hours.ago) }

      it "updates the sleep record to clocked out state" do
        result = described_class.call(user: user)

        expect(result).to eq(sleep_record.reload)
        expect(result.state).to eq("clocked_out")
        expect(result.clocked_out_at).to be_present
        expect(result.duration).to be_within(5).of(28_800) # approximately 8 hours in seconds
      end
    end

    context "when user has no active sleep records" do
      it "raises a NotClockedIn error" do
        expect do
          described_class.call(user: user)
        end.to raise_error(SleepError::NotClockedIn)
      end
    end

    context "when user has only clocked out sleep records" do
      before do
        create(:sleep_record,
               user: user,
               state: "clocked_out",
               clocked_in_at: 1.day.ago,
               clocked_out_at: 12.hours.ago,
               duration: 12.hours.to_i)
      end

      it "raises a NotClockedIn error" do
        expect do
          described_class.call(user: user)
        end.to raise_error(SleepError::NotClockedIn)
      end
    end

    context "when user has multiple active sleep records" do
      it "clocks out the first active record found" do
        older_record = create(:sleep_record, user: user, clocked_in_at: 10.hours.ago)
        create(:sleep_record, user: user, clocked_in_at: 7.hours.ago)

        result = described_class.call(user: user)

        # The first record should be clocked out
        expect(result.id).to eq(older_record.id)
        expect(result.state).to eq("clocked_out")

        # There should still be one record clocked in
        expect(user.sleep_records.clocked_in.count).to eq(1)
      end
    end
  end
end
