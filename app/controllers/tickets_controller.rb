class TicketsController < ApplicationController
  def print
    @ticket = Ticket.find(params[:id])
    # Do the prawn thing
  end

  def reclaim
    @ticket = Ticket.find(params[:id])
  end

  def index
    @tickets = Ticket.includes(:containers).includes(:inventory).includes(:items).all
  end

  def create
    @ticket = Ticket.new(ticket_params)
    if (@ticket.save)
      redirect_to ticket_path(@ticket)
    else
      flash[:notice] = "An error occurred, try again?"
      render :new
    end
  end

  def new
    @ticket = Ticket.new
  end

  def show
    @ticket = Ticket.includes(:containers).includes(:inventory).find(params[:id])
  end
private
  def ticket_params
    params.require(:ticket).permit(:comment, :partner_id, :inventory_id)
  end
end
