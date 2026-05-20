class AddressesController < ApplicationController
  before_action :set_address, only: [:edit, :update, :destroy]

  def index
    @addresses =
      user_signed_in? ?
        current_user.addresses.order(created_at: :desc) :
        []
  end

  def new
    @address = Address.new
  end

  def create

    @address = Address.new(address_params)

    if user_signed_in?
      @address.user = current_user
    end

    if @address.save

      session[:guest_address_id] = @address.id

      redirect_to checkout_path

    else

      render :new,
             status: :unprocessable_entity

    end

  end

  def edit
  end

  def update
    if @address.update(address_params)
      redirect_to addresses_path,
                  notice: "Address updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @address.destroy

    redirect_to addresses_path,
                notice: "Address deleted successfully"
  end

  private

  def set_address

    @address =
      if user_signed_in?
        current_user.addresses.find(params[:id])
      else
        Address.find(params[:id])
      end

  end

  def address_params
    params.require(:address).permit(
      :full_name,
      :phone_number,
      :address_line_1,
      :address_line_2,
      :city,
      :state,
      :postal_code,
      :country
    )
  end
end