class CountersController < ApplicationController
  skip_forgery_protection only: :count_up

  def count_up
    new_count = nil
    Counter.transaction do
      affected = Counter.where(id: "count_up").update_all("count = count + 1")
      if affected == 0
        raise ActiveRecord::RecordNotFound
      end
      new_count = Counter.find("count_up").count
    end
    render json: { count: new_count }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Counter not found" }, status: :not_found
  end
end
