require "rails_helper"

RSpec.describe Api::V1::SocialsController, type: :controller do
  let(:user) { create(:user) }
  let(:target_user) { create(:user) }
  let(:jwt_secret) { "test_secret" }
  let(:token) { JWT.encode({ username: user.username }, jwt_secret) }

  before do
    stub_const("ENV", ENV.to_hash.merge("JWT_SECRET_KEY" => jwt_secret))
    request.headers["Authorization"] = "Bearer #{token}"
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "#follow" do
    context "when successful" do
      it "calls the follow service and returns success message" do
        expect(Socials::FollowService).to receive(:call).with(
          user: user,
          target_user_id: target_user.id.to_s
        )

        post :follow, params: { user_id: target_user.id }

        expect(response).to have_http_status(:created)
        json_response = response.parsed_body
        expect(json_response["message"]).to eq("Successfully followed user")
      end
    end

    context "when user not found" do
      it "returns not found error" do
        expect(Socials::FollowService).to receive(:call).with(
          user: user,
          target_user_id: "non-existent-id"
        ).and_raise(UserError::NotFound)

        post :follow, params: { user_id: "non-existent-id" }

        expect(response).to have_http_status(:not_found)
        json_response = response.parsed_body
        expect(json_response["error"]["code"]).to eq("not_found")
      end
    end

    context "when already following" do
      it "returns unprocessable entity error" do
        expect(Socials::FollowService).to receive(:call).with(
          user: user,
          target_user_id: target_user.id.to_s
        ).and_raise(FollowError::AlreadyFollowed)

        post :follow, params: { user_id: target_user.id }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response["error"]["code"]).to eq("unprocessable_entity")
        expect(json_response["error"]["message"]).to include("already followed")
      end
    end

    context "when not authenticated" do
      before do
        request.headers["Authorization"] = nil
      end

      it "returns an unauthorized error" do
        post :follow, params: { user_id: target_user.id }

        expect(response).to have_http_status(:unauthorized)
        json_response = response.parsed_body
        expect(json_response["error"]["code"]).to eq("unauthorized")
      end
    end
  end

  describe "#unfollow" do
    context "when successful" do
      it "calls the unfollow service and returns success message" do
        expect(Socials::UnfollowService).to receive(:call).with(
          user: user,
          target_user_id: target_user.id.to_s
        )

        post :unfollow, params: { user_id: target_user.id }

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body
        expect(json_response["message"]).to eq("Successfully unfollowed user")
      end
    end

    context "when user not found" do
      it "returns not found error" do
        expect(Socials::UnfollowService).to receive(:call).with(
          user: user,
          target_user_id: "non-existent-id"
        ).and_raise(UserError::NotFound)

        post :unfollow, params: { user_id: "non-existent-id" }

        expect(response).to have_http_status(:not_found)
        json_response = response.parsed_body
        expect(json_response["error"]["code"]).to eq("not_found")
      end
    end

    context "when already unfollowed" do
      it "returns unprocessable entity error" do
        expect(Socials::UnfollowService).to receive(:call).with(
          user: user,
          target_user_id: target_user.id.to_s
        ).and_raise(FollowError::AlreadyUnfollowed)

        post :unfollow, params: { user_id: target_user.id }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = response.parsed_body
        expect(json_response["error"]["code"]).to eq("unprocessable_entity")
        expect(json_response["error"]["message"]).to include("already unfollowed")
      end
    end

    context "when not authenticated" do
      before do
        request.headers["Authorization"] = nil
      end

      it "returns an unauthorized error" do
        post :unfollow, params: { user_id: target_user.id }

        expect(response).to have_http_status(:unauthorized)
        json_response = response.parsed_body
        expect(json_response["error"]["code"]).to eq("unauthorized")
      end
    end
  end
end
