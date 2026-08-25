# Row actions live behind a per-row overflow menu -- see design.md, Row actions. Five labelled
# buttons made the actions column 331px on /distributions, wider than Total items, Total value and
# Status together; collapsed it is 60px.
#
# These helpers exist so a spec says what it means -- "cancel this request" -- rather than
# repeating the open-the-menu-then-click dance, and so the next change to the menu is one edit.
module RowActions
  # Open the overflow menu for a row and click one of its actions.
  #
  #   click_row_action "Reclaim"
  #   click_row_action "Edit", row: "Pawnee Pregnancy Center"
  def click_row_action(action, row: nil)
    open_row_menu(row: row).click_on(action)
  end

  # Open the menu and return the panel, for asserting on what is in it.
  #
  # Works whether or not the caller has already scoped to a row with `within`: several specs do,
  # and hunting for a `tbody tr` inside a `tr` finds nothing. The panel is `position: fixed` so it
  # can escape `.table-scroll`, but it is still a descendant of the row in the DOM, so a scoped
  # `find` still reaches it.
  def open_row_menu(row: nil)
    scope =
      if row
        find("tbody tr", text: row, match: :first)
      elsif has_selector?("[data-popover-target=trigger]", count: 1, wait: 0)
        self
      else
        find("tbody tr", match: :first)
      end

    scope.find("[data-popover-target=trigger]").click
    scope.find("[data-popover-target=panel]", visible: true)
  end
end

RSpec.configure do |config|
  config.include RowActions, type: :system
end
