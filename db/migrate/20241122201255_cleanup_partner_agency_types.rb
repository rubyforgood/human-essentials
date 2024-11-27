class CleanupPartnerAgencyTypes < ActiveRecord::Migration[7.1]
  # based on veesus' work in PR 4261

  def up
     # Some agency types have trailing spaces -- need tp get rid of them first

     update 'UPDATE partner_profiles SET agency_type = TRIM(agency_type)'


    mapping = [['Vocational training program','CAREER'],
               ['Church','CHURCH'],
               ['Church','CHURCH'],
               ['Church ministry','CHURCH'],
               ['Crisis/Disaster services','CRISIS'],
               ['Domestic Violence/Non-Profit','DOMV'],
               ['Child Care Center','ECE'],
               ['Education','EDU'],
               ['Educational','EDU'],
               ['Non-Profit - Education','EDU'],
               ['public elementary school','ES'],
               ['Church food pantry','FOOD'],
               ['Food bank','FOOD'],
               ['Food pantry','FOOD'],
               ['Food Pantry','FOOD'],
               ['Food Pantry - Emergency Diaper Distribution','FOOD'],
               ['Foster Care','FOSTER'],
               ['Government Agency/Affiliate','GOVT'],
               ['Community health program','HEALTH'],
               ['Home visits','HOMEVISIT'],
               ['Public School','HS'],
               ['Infant/Child Pantry/Closet','INFPAN'],
               ['ASO','HEALTH'],
               ['Case Management','OUTREACH'],
               ['Child Advocacy Center','CHILD'],
               ['Child Placing Agency','FOSTER'],
               ['Community Ministry','CHURCH'],
               ['Community outreach services','OUTREACH'],
               ['Community Service Organization','OUTREACH'],
               ['Diaper agency','BNB'],
               ['Diaper Bank','BNB'],
               ['Emergency Crisis/Human Trafficking/Refuee Service','REF'],
               ['Human Services','OUTREACH'],
               ['Maternity Home','PREG'],
               ['Mental Health','MHEALTH'],
               ['Non-Profit Victim Services and Family Resource Center','FAMILY'],
               ['Non-Profit. Clothing, Food and Diaper Assistance','INFPAN'],
               ['Nonprofit/School','EDU'],
               ['Perinatal Mental Health Peer Support','MHEALTH'],
               ['Primary Care Doctor','HEALTH'],['Public Health','HEALTH'],
               ['Reproductive Health Care, Maternity Services','PREG'],
               ['Safety Net Organization','OUTREACH'],
               ['School','District'],
               ['School District','District'],
               ['School District','District'],
               ['Women Substance Abuse','TREAT'],
               ['Law Enforcement Agency','POLICE'],
               ['Pregnancy Center - Charitable Health','PREG'],
               ['Nonprofit preschool','PRESCH'],
               ['Child abuse resource center','ABUSE'],
               ['Career technical training','CAREER'],
               ['Community development corporation','CDC'],
               ['Early childhood services','CHILD'],
               ['Church outreach ministry','CHURCH'],
               ['Developmental disabilities program','DISAB'],
               ['Domestic violence shelter','DOMV'],
               ['Education program','EDU'],
               ['School - Elementary School','ES'],
               ['Family resource center','FAMILY'],
               ['Food bank/pantry','FOOD'],
               ['Head Start/Early Head Start','HEADSTART'],
               ['Community health program or clinic','HEALTH'],
               ['Homeless resource center','HOMELESS'],
               ['Hospital','HOSP'],
               ['Hospital','HOSP'],
               ['School - High School','HS'],
               ['Correctional Facilities / Jail / Prison / Legal System','LEGAL'],
               ['School - Middle School','MS'],
               ['Pregnancy resource center','PREG'],
               ['Pregnancy Resource Center','PREG'],
               ['Refugee resource center','REF'],
               ['Treatment clinic','TREAT'],
               ['Women, Infants and Children','WIC']]

    mapping.each do |type_pair|
      profiles = Partners::Profile.where(agency_type: type_pair[0])
      profiles.each do |profile|
        profile.agency_type = Partner::AGENCY_TYPES[type_pair[1]]
        profile.save!
      end

    end


    profiles = Partners::Profile
                 .where.not(agency_type: Partner::AGENCY_TYPES.values)
                 .in_batches

    profiles.each_record do |profile|
      profile.other_agency_type = profile.agency_type
      profile.agency_type = Partner::AGENCY_TYPES['OTHER']
      profile.save!
    end

  end

  def down
    # Irreversible data migration
  end
end
