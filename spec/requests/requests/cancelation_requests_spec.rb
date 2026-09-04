RSpec.describe "Requests::Cancelation", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }

  before { sign_in(user) }

  describe "POST #create" do
    let(:request_record) { create(:request, organization: organization) }

    it "cancels the request and returns to the list" do
      post request_cancelation_path(request_id: request_record.id),
        params: {cancelation: {reason: "Partner withdrew it"}}

      expect(response).to redirect_to(requests_path)
      expect(request_record.reload.discarded_at).to be_present
      expect(request_record.discard_reason).to eq("Partner withdrew it")
    end

    # The defect this covers: it used to redirect back to the cancellation form. Neither of
    # `RequestDestroyService`'s failures is retryable -- both are states -- so that left the user in
    # front of a control that could never succeed, with the reason they had written discarded. The
    # colleague-got-there-first case is the realistic one.
    context "when the request has already been cancelled" do
      before { request_record.update!(discarded_at: Time.current, status: :cancelled) }

      it "sends the user to the request rather than back to a form that cannot succeed" do
        post request_cancelation_path(request_id: request_record.id),
          params: {cancelation: {reason: "typing this again will not help"}}

        expect(response).to redirect_to(request_path(request_record))
        # The negative assertion is the one that matters: returning to the form is the bug.
        expect(response).not_to redirect_to(new_request_cancelation_path(request_id: request_record.id))
      end

      it "says why, in a sentence" do
        post request_cancelation_path(request_id: request_record.id),
          params: {cancelation: {reason: "anything"}}

        expect(flash[:error]).to eq(
          "Request #{request_record.id} could not be cancelled -- it has already been cancelled."
        )
      end
    end

    # `request_path` on an id that resolves to nothing would answer the failure with a 404, so this
    # one falls back to the list.
    context "when the request does not exist" do
      it "falls back to the request list" do
        post request_cancelation_path(request_id: 999_999),
          params: {cancelation: {reason: "anything"}}

        expect(response).to redirect_to(requests_path)
        expect(flash[:error]).to include("could not be cancelled -- we could not find it.")
      end
    end
  end
end
