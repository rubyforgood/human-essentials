# Driving the trend pages' Compare control.
#
# It applies on *close*, not on change: four choices are one request rather than four, which is the
# whole reason it replaced a checkbox on every table row. So a spec has to open it, tick, and close
# it -- and closing is what makes the page update.
module ComparePicker
  def open_compare
    find("#filters_compare_trigger").click
    expect(page).to have_css("[role=dialog][aria-label='Choose what to compare']")
  end

  # Type first, so this works whether the list is three long or three hundred.
  def compare_with(*labels)
    open_compare
    labels.each do |label|
      within("[role=dialog][aria-label='Choose what to compare']") do
        fill_in "Search categories and items", with: label
        check label, allow_label_click: true
      end
    end
    close_compare(applies: true)
  end

  # `applies:` waits for the navigation, and it is not optional politeness. `close()` sets
  # `aria-expanded="false"` *synchronously* and submits after, so waiting only for the attribute
  # returns while the old page is still on screen -- and the assertion after it reads the chart that
  # was there before. That failed intermittently until it was waited for properly.
  def close_compare(applies: false)
    find("body").send_keys(:escape)
    expect(page).to have_css("#filters_compare_trigger[aria-expanded=false]")
    expect(page).to have_current_path(/compare_with/) if applies
  end
end

RSpec.configure do |config|
  config.include ComparePicker, type: :system
end
