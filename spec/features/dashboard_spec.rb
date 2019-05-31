RSpec.feature "Dashboard", type: :feature do
  let!(:diaper_donation_on_today) do
    create(:donation, :diaper_drive, issued_at: Time.current)
  end
  let!(:diaper_donation_on_last_month) do
    create(:donation, :diaper_drive, issued_at: Time.current - 1.month)
  end
  let!(:diaper_donation_on_last_yesterday) do
    create(:donation, :diaper_drive, issued_at: Time.current.yesterday)
  end
  let!(:diaper_donation_on_last_week) do
    create(:donation, :diaper_drive, issued_at: Time.current.last_week)
  end

  before do
    sign_in(@user)
  end

  scenario 'Filter Diaper drive by date', js: true do
    visit root_path

    expect(page).to have_content("4 Diaper Drives year to date for")

    filter_by_date('today')
    expect(page).to have_content("1 Diaper Drives today for")

    filter_by_date('last_month')
    expect(page).to have_content("1 Diaper Drives last month for")

    filter_by_date('yesterday')
    expect(page).to have_content("1 Diaper Drives yesterday for")

    filter_by_date('week_to_date')
    expect(page).to have_content("2 Diaper Drives week to date for")
  end

  def filter_by_date(option)
    within '#dashboard_filter_interval' do
      find("option[value=#{option}]").click
    end
  end
end
