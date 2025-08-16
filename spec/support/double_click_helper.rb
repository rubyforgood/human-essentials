# Simulates the user double clicking on an element specified by a css_selector
# by using the API provided by Ferrum to manipulate the browser directly.
#
# @param css_selector [String] The CSS selector for the element to be double clicked.
#
# @example Usage
#   # Make sure the element is there
#   expect(page.find('a.btn.btn-success.btn-md[href*="/picked_up"]')).to have_content("Distribution Complete")
#
#   # Double click it
#   ferrum_double_click('a.btn.btn-success.btn-md[href*="/picked_up"]')
#
#   # Assert something based on the double click.
def ferrum_double_click(css_selector)
  node = Capybara.page.driver.browser.at_css(css_selector)
  x, y = node.find_position
  mouse = node.page.mouse
  mouse.move(x:, y:)
  mouse.down
  mouse.up
  sleep(0.05)
  mouse.down
  mouse.up
end
