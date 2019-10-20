PrawnRails.config do |config|
  config.page_layout = :portrait
  config.page_size   = "A4"
  config.skip_page_creation = false
  config.font_families = { "OpenSans": {
    :normal => Rails.root.join('app','assets','fonts', 'open_sans', 'OpenSans-Regular.ttf'),
    :italic => Rails.root.join('app','assets','fonts', 'open_sans', 'OpenSans-Italic.ttf'),
    :bold => Rails.root.join('app','assets','fonts', 'open_sans', 'OpenSans-Bold.ttf'),
    :bold_italic => Rails.root.join('app','assets','fonts', 'open_sans', 'OpenSans-BoldItalic.ttf'),
  } }
  config.font = "OpenSans"
end
