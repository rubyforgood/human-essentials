class DataFixForMhmAndAad < ActiveRecord::Migration[7.2]
  def up
    # This is a one-time, one-way data fix for MHM and AAD.  See support ticket starting Sept 9, 2024, 1327

    return unless Rails.env.production?

    # This request should be marked fulfilled and associated with distribution 74466.  We have checked that no request is already associated with that distribution

    request = Request.find("39408")
    request.distribution_id = "74466"
    request.status = 2
    request.save!


    ## these addoitinal 3 requests have been identified as having the status 'started', when they should be 'fulfilled'
    # They already have distributions associated with them

    ["42063", "37900"].each do |request_id|
      request = Request.find(request_id)
      request.status = 2
      request.save!
    end


  end
  def down
    # treating this as irreversible.  Though I suppose technically we could.
  end
end
