class CleanupInvalidPartnerProfiles < ActiveRecord::Migration[7.1]
  def up
    # ActiveRecord::Base.logger = Logger.new(STDOUT)
    invalid_profiles = Partners::Profile.all.reject(&:valid?)

    return if !invalid_profiles.present?

    invalid_profiles.each do |profile|
      # address invalid social media section

      unless (profile.website.present? ||
        profile.twitter.present? ||
        profile.facebook.present? ||
        profile.instagram.present? ||
        profile.no_social_media_presence ||
        profile.partner.partials_to_show.exclude?("media_information"))
        profile.no_social_media_presence = true
      end

      # address no request types set

      unless(profile.enable_quantity_based_requests || profile.enable_individual_requests || profile.enable_child_based_requests)
        profile.enable_quantity_based_requests = profile.partner.organization.enable_quantity_based_requests
        profile.enable_individual_requests = profile.partner.organization.enable_individual_requests
        profile.enable_child_based_requests = profile.partner.organization.enable_child_based_requests
      end



      # address bad pickup email

      unless profile.valid?
        # if profile is not valid at this point,  it is a bad pickup email

        pick_up = profile.pick_up_email
        pick_up.downcase!
        pick_up.strip!
        if pick_up == "none" or pick_up == "na" or pick_up == "n/a" or pick_up == "see above"
          profile.pick_up_email = ""
        else
          profile.pick_up_email.gsub!("/",",")
          profile.pick_up_email.gsub!(";",",")
          profile.pick_up_email.gsub!(" or ", ", ")
          profile.pick_up_email.gsub!(" and ", ", ")
          profile.pick_up_email.gsub!(" & ", ", ")
        end

        if(!profile.valid?)  ## If we can't fix the email,  append it to the name so we don't lose the information aspect
          profile.pick_up_name += ", email: " + profile.pick_up_email
          profile.pick_up_email = ""
        end
      end

      profile.save!

    end
  end
  def down
  # irreversible
  end
end
