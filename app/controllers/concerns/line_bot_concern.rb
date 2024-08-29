module LineBotConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_client
  end

  private

  def log_event(event, type = nil)
    @logged ||= {}
    return if @logged[event]

    user_id = event['source']['userId']
    type ||= event.type.upcase

    Rails.logger.info "Handling [#{type}] event for user [#{user_id}]"
    @logged[event] = true
  end

  def set_client
    @line_service = LineService::Client.new
  end
end
