module DiaperDriveHelper
  def is_virtual(diaper_drive:)
    raise StandardError, 'No product drive was provided' if diaper_drive.blank?

    diaper_drive.virtual? ? 'Yes' : 'No'
  end
end
