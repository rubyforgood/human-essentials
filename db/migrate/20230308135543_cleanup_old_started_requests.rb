class CleanupOldStartedRequests < ActiveRecord::Migration[7.0]
  def up
    Request.where(status: 'started').where('updated_at < ?', 1.month.ago).each do |request|
      request.update!(status: 'fulfilled')
    end
  end
  def down

  end
end
