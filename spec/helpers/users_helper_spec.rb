require "rails_helper"

RSpec.describe UsersHelper, type: :helper do
	context 'returns the time for a specific user timezone' do
		before do
			allow(IpInfoService).to receive(:get_timezone).and_return("America/New_York")
		end

		it 'should return date and time for Denver using IpInfoService' do
			expect(get_time_at_timezone.strftime("%I:%M %p on %m/%d/%Y")).to eq(Time.now.in_time_zone("America/New_York").strftime("%I:%M %p on %m/%d/%Y"))
		end
	end
end

