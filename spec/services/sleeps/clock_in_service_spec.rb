require "rails_helper"

RSpec.describe Sleeps::ClockInService do
  describe "#call" do
    let(:user) { create(:user) }

    context "when user has no active sleep records" do
      it "creates a new sleep record" do
        expect do
          described_class.call(user: user)
        end.to change(SleepRecord, :count).by(1)

        sleep_record = SleepRecord.last
        expect(sleep_record.user).to eq(user)
        expect(sleep_record.clocked_in_at).to be_present
        expect(sleep_record.state).to eq("clocked_in")
        expect(sleep_record.duration).to eq(0)
      end
    end

    context "when user already has an active sleep record" do
      it "raises an AlreadyClockedIn error" do
        create(:sleep_record, user: user, state: "clocked_in")

        expect do
          described_class.call(user: user)
        end.to raise_error(SleepError::AlreadyClockedIn)
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

      it "creates a new sleep record" do
        expect do
          described_class.call(user: user)
        end.to change(SleepRecord, :count).by(1)

        sleep_record = user.sleep_records.order(created_at: :desc).first
        expect(sleep_record.state).to eq("clocked_in")
      end
    end
  end
end
