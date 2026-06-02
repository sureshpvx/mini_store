# app/controllers/contact_messages_controller.rb
class ContactMessagesController < ApplicationController
  def create
    @message = ContactMessage.new(contact_message_params)

    if @message.save
      # Optional: notify yourself via email in production
      # AdminMailer.new_contact_message(@message).deliver_later
      redirect_to contact_path, notice: "Message received. We will respond within 24 hours."
    else
      redirect_to contact_path, alert: "Please fill in all fields correctly."
    end
  end

  private

  def contact_message_params
    params.require(:contact_message).permit(:name, :email, :message)
  end
end