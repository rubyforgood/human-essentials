require_relative "organization_page"

class OrganizationNewDonationPage < OrganizationPage
  include DonationSourceFilterLables

  def org_page_path
    # relative path within organization's subtree
    "donations/new"
  end

  def add_line_item
    find_link(id: :__add_line_item).click

    self
  end

  def create_new_product_drive
    click_on :diaper_drive_submit

    self
  end

  def has_donation_site_select?
    has_select? id: :donation_donation_site_id
  end

  def has_manufacturer_select?
    has_select? id: :donation_manufacturer_id
  end

  def has_new_product_drive_entry?
    has_selector? new_product_drive_entry_selector
  end

  def has_no_new_product_drive_entry?
    # See https://github.com/teamcapybara/capybara#asynchronous-javascript-ajax-and-friends
    has_no_selector? new_product_drive_entry_selector
  end

  def has_product_drive_participant_select?
    has_select? id: product_drive_participant_select_id
  end

  def item_name_options
    last_line_item_name_select
      .all("option")
      .map(&:text)
      .to_a[2..]
  end

  def product_drive_name_options
    product_drive_select
      .all("option")
      .map(&:text)
      .to_a[1..-2] # skip <blank> and "---Create new Product Drive---"
  end

  def save_donation
    click_button "Save"

    self
  end

  def set_donation_date(date)
    fill_in :donation_issued_at, with: date.strftime("%m/%d/%Y")

    self
  end

  def set_last_line_item_name(item_name)
    last_line_item_name_select.select item_name

    self
  end

  def set_last_line_item_quantity(quantity)
    last_line_item_quantity = all(".donation_line_items_quantity")
      .last
      .find_field(placeholder: "Quantity")

    last_line_item_quantity.fill_in with: quantity

    self
  end

  def set_money_raised(amount)
    fill_in :donation_money_raised_in_dollars, with: "1,234.56"

    self
  end

  def set_new_product_drive_name(name)
    fill_in :diaper_drive_name, with: name

    self
  end

  def set_new_product_start_date(date)
    fill_in :diaper_drive_start_date, with: date

    self
  end

  def set_product_drive(drive_name)
    if drive_name == :create_new_product_drive
      drive_name = "---Create new Product Drive---"
    end

    product_drive_select.select drive_name

    self
  end

  def set_product_drive_participant(participant_name)
    select participant_name, from: product_drive_participant_select_id

    self
  end

  def set_source(donation_source)
    filter_label = DONATION_SOURCE_FILTER_LABELS.fetch(donation_source) # errors if not present
    select filter_label, from: :donation_source

    self
  end

  def set_storage_location(location_name)
    select location_name, from: :donation_storage_location_id

    self
  end

  private

  def last_line_item_name_select
    all(".donation_line_items_item_id select")
      .last
  end

  def new_product_drive_entry_selector
    "#modal_new.modal"
  end

  def product_drive_participant_select_id
    :donation_diaper_drive_participant_id
  end

  def product_drive_select
    find "select#donation_diaper_drive_id"
  end
end
