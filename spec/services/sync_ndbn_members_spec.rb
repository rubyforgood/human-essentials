describe SyncNDBNMembers do
  describe ".sync" do
    subject { -> { described_class.sync } }
    let(:ndbn_member_id) { 200040 }
    let(:account_name) { "New Super Baby" }
    let(:fake_html_body) do
      <<-HTML
      <table class="contentpaneopen">
      <tbody><tr>
      <td valign="top"><div class="content-wrapper" style="width: 690px;">
      <h1>Organizational Member IDs</h1>
      <p><strong>ID&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;Account Name</strong></p>
      <p><span style="font-size: 15px;">20040&nbsp;&nbsp;&nbsp; (914) Cares</span></p>
      <p>#{ndbn_member_id}&nbsp;&nbsp;&nbsp; #{account_name}</p>

      </div></td>
      </tr>

      </tbody></table>
      HTML
    end

    before do
      stub_request(:get, SyncNDBNMembers::NDBN_MEMBERS_PAGE).to_return(body: fake_html_body)
    end

    context "when the HTTP request does not get a response of 200" do
      let(:failed_status_code) { 500 }
      before do
        stub_request(:get, SyncNDBNMembers::NDBN_MEMBERS_PAGE).to_return(status: failed_status_code)
      end

      it "should raise an error regarding the response code" do
        expect { subject.call }.to raise_error("SyncNDBNMembers.sync failed due to getting a status code of #{failed_status_code}")
      end
    end

    context "when the HTTP request is successful" do
      before do
        stub_request(:get, SyncNDBNMembers::NDBN_MEMBERS_PAGE).to_return(body: fake_html_body)
      end

      context "when there are no exisiting NDBN Member records" do
        it "should create the NDBN Member records" do
          expect { subject.call }.to change { NDBNMember.count }.from(0).to(2)
        end
      end

      context "when the account name of a NDBN Member has changed" do
        let(:old_account_name) { "Super Baby" }

        before do
          create(:ndbn_member, ndbn_member_id: ndbn_member_id, account_name: old_account_name)
        end

        it "should update the account name of the corresponding NDBN Member" do
          expect { subject.call }.to change { NDBNMember.find_by(ndbn_member_id: ndbn_member_id).account_name }.from(old_account_name).to(account_name)
        end
      end

      context "when no new NDBN Member has been added" do
        it "should not add any new NDBN Members" do
          expect { subject.call }.to change { NDBNMember.count }.from(0).to(2)
          expect { subject.call }.not_to change { NDBNMember.count }
        end
      end
    end
  end
end
