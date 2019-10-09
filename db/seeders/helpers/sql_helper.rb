module Helpers
  class SqlHelper
    attr_accessor :klass, :organization

    def self.random_record_for_org(klass, organization)
      new(klass, organization).random_record_for_org
    end

    def initialize(klass, organization)
      @klass = klass
      @organization = organization
    end

    def random_record_for_org
      klass.where(organization: organization).limit(1).order(Arel.sql('random()')).first
    end
  end
end
