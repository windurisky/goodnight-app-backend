require "rails_helper"

RSpec.describe Api::V1::SleepRecordsController, type: :controller do
  let(:user) { create(:user) }
  let(:jwt_secret) { "test_secret" }
  let(:token) { JWT.encode({ username: user.username }, jwt_secret) }

  before do
    stub_const("ENV", ENV.to_hash.merge("JWT_SECRET_KEY" => jwt_secret))
    request.headers["Authorization"] = "Bearer #{token}"
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "#clock_in" do
    context "when successful" do
      it "calls the clock in service and returns success message" do
        sleep_record = build(:sleep_record, user: user, id: "test-uuid")

        expect(Sleeps::ClockInService).to receive(:call).with(
          user: user
        ).and_return(sleep_record)

        post :clock_in

        expect(response).to have_http_status(:created)
        json_response = response.parsed_body
        expect(json_response["message"]).to eq("Clock in successful")
        expect(json_response["sleep_record_id"]).to eq("test-uuid")
      end
    end

    context "when already clocked in" do
      it "returns a bad request error" do
        expect(Sleeps::ClockInService).to receive(:call).with(
          user: user
        ).and_raise(SleepError::AlreadyClockedIn)

        post :clock_in

        expect(response).to have_http_status(:bad_request)
        json_response = response.parsed_body
        expect(json_response["error"]["code"]).to eq("already_clocked_in")
        expect(json_response["error"]["message"]).to include("already clocked in")
      end
    end

    context "when not authenticated" do
      before do
        request.headers["Authorization"] = nil
      end

      it "returns an unauthorized error" do
        post :clock_in

        expect(response).to have_http_status(:unauthorized)
        json_response = response.parsed_body
        expect(json_response["error"]["code"]).to eq("unauthorized")
      end
    end
  end

  describe "#clock_out" do
    context "when successful" do
      it "calls the clock out service and returns success message" do
        sleep_record = build(:sleep_record, user: user, duration: 28_800, state: "clocked_out")

        expect(Sleeps::ClockOutService).to receive(:call).with(
          user: user
        ).and_return(sleep_record)

        post :clock_out

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body
        expect(json_response["message"]).to eq("Clock out successful")
        expect(json_response["duration"]).to eq(28_800)
      end
    end

    context "when not clocked in" do
      it "returns a bad request error" do
        expect(Sleeps::ClockOutService).to receive(:call).with(
          user: user
        ).and_raise(SleepError::NotClockedIn.new)

        post :clock_out

        expect(response).to have_http_status(:bad_request)
        json_response = response.parsed_body
        expect(json_response["error"]["code"]).to eq("not_clocked_in")
        expect(json_response["error"]["message"]).to eq("You are not clocked in, must clock in first")
      end
    end

    context "when not authenticated" do
      before do
        request.headers["Authorization"] = nil
      end

      it "returns an unauthorized error" do
        post :clock_out

        expect(response).to have_http_status(:unauthorized)
        json_response = response.parsed_body
        expect(json_response["error"]["code"]).to eq("unauthorized")
      end
    end
  end
end
