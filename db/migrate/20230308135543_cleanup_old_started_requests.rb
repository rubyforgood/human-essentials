class CleanupOldStartedRequests < ActiveRecord::Migration[7.0]
  def up
    Request.where(status: 'started').each do |request|
      # Assumption:  distributions are made in response to requests (at least normally), so if there is a
      # distribution before the next started or fulfilled request,  it 'belongs' to (was created in response to)
      # the started request

      request_update_time = request.updated_at.to_time
      request_range = (request_update_time+1.second)..(Time.now)

      next_request = Request.where(updated_at: request_range).where("status = 1 or status = 2").first  # started or fulfilled
      if(next_request)
        dist_range = (request_update_time)..(next_request.updated_at.to_time)
        dist = Distribution.where(created_at: dist_range).first
        if(dist)
          request.update!(status: 'fulfilled')
          end
      end
    end
  end
  def down

  end
end
