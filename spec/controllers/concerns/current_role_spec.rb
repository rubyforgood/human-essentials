describe CurrentRole do
  let(:controller_class) do
    described_module = described_class

    Class.new do
      include described_module

      def initialize(current_user, session)
        self.current_user = current_user
        self.session = session
      end

      private

      attr_accessor :current_user, :session
    end
  end

  let(:controller) { controller_class.new current_user, session }
  let(:current_user) { user }
  let(:user) { create :user }
  let(:session) { {} }

  def user_role_for(role)
    UsersRole.find_or_create_by! role: role, user: user
  end

  let!(:current_role) { user.roles.first || create(:role) }
  let!(:other_role) { create :role }
  let!(:current_user_role) { user_role_for(current_role).tap(&:activate!) }
  let!(:other_user_role) { user_role_for(other_role) if may_access_session_role? }
  let(:may_access_session_role?) { true }

  describe "#current_role" do
    subject { controller.current_role }

    context "when current user is present and session does not have current_role" do
      it { is_expected.to eq current_role }
    end

    context "when current user is blank" do
      let(:current_user) { nil }

      it { is_expected.to be_nil }
    end

    context "when session has current_role" do
      let(:session) { {current_role: other_role.id}.with_indifferent_access }

      shared_examples "session clearing" do
        it "removes current_role from session" do
          expect { controller.current_role }
            .to change { session }.to({})
        end
      end

      context "when user may access session role" do
        it { is_expected.to eq other_role }
        include_examples "session clearing"
      end

      context "when user may not access session role" do
        let(:may_access_session_role?) { false }

        it { is_expected.to eq current_role }
        include_examples "session clearing"
      end
    end

    describe "caching" do
      def set_current_user_role(role)
        allow(user).to receive(:current_role).and_return role
      end

      before { set_current_user_role current_role }

      context "when first called" do
        it "activates the appropriate user role" do
          expect { controller.current_role }
            .to change { current_user_role.reload.last_active_at }
        end

        it "does not update other user roles" do
          expect { controller.current_role }
            .not_to change { other_user_role.reload }
        end
      end

      context "when called again" do
        before { controller.current_role }

        context "with no change to current role" do
          it "does not update active user role" do
            expect { controller.current_role }
              .not_to change { current_user_role.reload }
          end
        end

        context "when current user role changes" do
          before { set_current_user_role other_role }

          it "activates new user role" do
            expect { controller.current_role }
              .to change { other_user_role.reload.last_active_at }
          end

          it "does not update previous user role" do
            expect { controller.current_role }
              .not_to change { current_user_role.reload }
          end
        end
      end
    end
  end

  describe "#set_current_role" do
    let(:role) { current_role }
    let(:user_role) { current_user_role }

    it "activates role" do
      expect { controller.set_current_role role }
        .to change { user_role.reload.last_active_at }
    end

    it "reloads user's current role" do
      allow(user).to receive(:reload_current_role).and_call_original
      controller.set_current_role role
      expect(user).to have_received :reload_current_role
    end
  end
end
