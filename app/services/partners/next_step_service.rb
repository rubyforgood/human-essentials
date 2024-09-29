module Partners
  class NextStepService
    def initialize(partner, submitted_partial)
      @partner = partner
      @submitted_partial = submitted_partial
    end

    def call
      next_step
    end

    private

    # | Partial                         | Type    | Default   | Next                            |
    # | ------------------------------- | ------- | --------- | ------------------------------- |
    # | agency_information              | static  | expanded  | program_delivery_address         |
    # | program_delivery_address        | static  | collapsed | media_information               |
    # | media_information               | dynamic | collapsed | agency_stability                |
    # | agency_stability                | dynamic | collapsed | organizational_capacity         |
    # | organizational_capacity         | dynamic | collapsed | sources_of_funding              |
    # | sources_of_funding              | dynamic | collapsed | area_served                     |
    # | area_served                     | dynamic | collapsed | population_served               |
    # | population_served               | dynamic | collapsed | executive_director              |
    # | executive_director              | dynamic | collapsed | pick_up_person                  |
    # | pick_up_person                  | dynamic | collapsed | agency_distribution_information |
    # | agency_distribution_information | dynamic | collapsed | attached_documents              |
    # | attached_documents              | dynamic | collapsed | partner_settings                |
    # | partner_settings                | static  | collapsed | NA                              |
    def next_step
      if @partner.partials_to_show.include?(@submitted_partial)
        next_partner_partial(@submitted_partial)
      elsif @submitted_partial == "agency_information"
        "program_delivery_address"
      elsif @submitted_partial == "program_delivery_address"
        @partner.partials_to_show.first
      elsif @submitted_partial == "partner_settings"
        # Should never get here because app/views/partners/profiles/step/_partner_settings_form.html.erb
        # doesn't have a next button
        "agency_information"
      else
        "agency_information"
      end
    end

    def next_partner_partial(submitted_partial)
      index = @partner.partials_to_show.index(submitted_partial)
      return "agency_information" if index.nil?

      if index == @partner.partials_to_show.length - 1
        "partner_settings"
      else
        @partner.partials_to_show[index + 1]
      end
    end
  end
end
