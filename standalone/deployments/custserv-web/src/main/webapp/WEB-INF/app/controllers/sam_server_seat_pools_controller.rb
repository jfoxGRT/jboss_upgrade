class SamServerSeatPoolsController < SeatPoolsController
  
  def show
    @seat_pool = SeatPool.find(params[:id])
  end
  
  
  
end
