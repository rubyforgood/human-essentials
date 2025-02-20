class FixFor20250120RequestProblem < ActiveRecord::Migration[7.2]
  def up
    # Merely marking request 44040 fulfilled.
    # It already has a distribution associated with it, so we don't have to fix that
    return unless Rails.env.production?
    request = Request.find("44040")
    request.status = 2
    request.save!
  end
end
