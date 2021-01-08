module DiaperDriveHelper
  def is_virtual(diaper_drive)
    return 'No' if diaper_drive.blank?

    diaper_drive.virtual? ? 'Yes' : 'No'
  end
end
