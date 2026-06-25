module Admin
  class ChatLogsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin

    def index
      @chat_logs = ChatLog.recent
      @today_count = ChatLog.today.count
      @resolution_rate = ChatLog.resolution_rate
      @top_queries = ChatLog.top_queries
    end

    private

    def require_admin
      redirect_to root_path unless current_user&.admin?
    end
  end
end
