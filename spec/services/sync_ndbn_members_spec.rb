describe SyncNDBNMembers do
  let(:small_input) { File.open(Rails.root.join("spec", "fixtures", "ndbn-small-import.csv")) }
  let(:non_csv) { File.open(Rails.root.join("spec", "fixtures", "files", "logo.jpg")) }

  describe "#sync_from_csv" do
    # Small CSV Input
    # Updated: 1/10/2024,
    # NDBN Member Number,Member Name
    # 10000 Homeless Shelter
    # 20000 Other Spot
    # 20000                       #Blank
    # 30000 Amazing Place
    # 10000 Pawnee
    context "with a small file" do
      it "overwrites existing names with new names if shared member id" do
        want = ["Other Spot", "Amazing Place", "Pawnee"]

        SyncNDBNMembers.upload(small_input)

        expect(NDBNMember.pluck(:account_name)).to match_array(want)
      end

      it "does not have errors if fields are nil" do
        errors = SyncNDBNMembers.upload(small_input)
        expect(errors).to be_empty
      end

      it "does not override if name is blank" do
        SyncNDBNMembers.upload(small_input)
        expect(NDBNMember.find_by(ndbn_member_id: 20000).account_name).to eq("Other Spot")
      end
    end

    context "with file that is nil" do
      it "does adds error" do
        errors = SyncNDBNMembers.upload(nil)

        expect(errors).to contain_exactly("CSV upload is required.")
      end
    end

    context "with file that is not CSV" do
      it "does adds error" do
        errors = SyncNDBNMembers.upload(non_csv)

        expect(errors).to contain_exactly("The CSV File provided was invalid.")
      end
    end

    context "if invalid values get past the regex" do
      before { allow(SyncNDBNMembers).to receive(:parse_csv).and_return([[1, nil], [2, nil]]) }

      it "returns array of errors" do
        errors = SyncNDBNMembers.upload(small_input)
        expect(errors).to contain_exactly(
          "Issue with 1:  -> Account name can't be blank",
          "Issue with 2:  -> Account name can't be blank"
        )
      end
    end
  end
end
