describe SyncNDBNMembers do
  let(:small_input) { File.open(Rails.root.join("spec", "fixtures", "ndbn-small-import.csv")) }
  let(:invalid_input) { File.open(Rails.root.join("spec", "fixtures", "ndbn-invalid-import.csv")) }
  let(:non_csv) { File.open(Rails.root.join("spec", "fixtures", "files", "logo.jpg")) }

  describe "#sync_from_csv" do
    # Updated: 1/10/2024,
    # NDBN Member Number,Member Name
    # 10000 Homeless Shelter
    # 20000 Other Spot
    # 30000 Amazing Place
    # 10000 Pawnee
    context "with a small file" do
      it "overwrites existing names with new names if shared member id" do
        want = ["Other Spot", "Amazing Place", "Pawnee"]

        SyncNDBNMembers.upload(small_input)
        expect(NDBNMember.pluck(:account_name)).to match_array(want)
      end
    end

    # NDBN Member Number,Member Name
    # string,Homeless Shelter
    # 2,
    context "with file with invalid values" do
      it "returns array of errors" do
        errors = SyncNDBNMembers.upload(invalid_input)
        expect(errors).to contain_exactly(
          "Issue with 'string,Homeless Shelter'-> NDBN member id must be an integer",
          "Issue with '2,'-> Account name can't be blank"
        )
      end
    end

    context "with file that is nil" do
      it "adds error" do
        errors = SyncNDBNMembers.upload(nil)

        expect(errors).to contain_exactly("CSV upload is required.")
      end
    end

    context "with file that is not CSV" do
      it "adds error" do
        errors = SyncNDBNMembers.upload(non_csv)

        expect(errors).to contain_exactly("The CSV File provided was invalid.")
      end
    end
  end
end
