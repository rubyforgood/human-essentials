class TicketsController < ApplicationController
  def print
    @ticket = Ticket.find(params[:id])
    # Do the prawn thing
  end

  def reclaim
    @ticket = Ticket.find(params[:id])
  end

  def index
    @tickets = Ticket.all
  end

  def create
    @ticket = Ticket.create(ticket_params)
    redirect_to ticket_path(@ticket)
  end

  def new
    @ticket = Ticket.new
  end

  def show
    @ticket = Ticket.find(params[:id])
  end
private
  def ticket_params
    params.require(:ticket).permit(:comment, :partner_id, :inventory_id)
  end
end
