module ConektaEvent
  class WebhookController < ActionController::Base
    before_action do
      if ConektaEvent.authentication_secret
        authenticate_or_request_with_http_basic do |username, password|
          password == ConektaEvent.authentication_secret
        end
      end
    end

    def event
      ConektaEvent.instrument(params)
      head :ok
    rescue ConektaEvent::UnauthorizedError => e
      log_error(e)
      head :unauthorized
    end

    private

    def log_error(e)
      logger.error e.message
      e.backtrace.each { |line| logger.error " #{line}" }
    end
  end
end
