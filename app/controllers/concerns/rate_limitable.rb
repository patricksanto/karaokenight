module RateLimitable
  extend ActiveSupport::Concern

  class_methods do
    def rate_limit(action:, to: 10, within: 1.minute, block: nil)
      before_action only: action do
        key = "rate_limit:#{controller_name}:#{action_name}:#{request.remote_ip}"
        count = Rails.cache.increment(key, 1, expires_in: within)

        if count && count > to
          if block
            instance_exec(&block)
          else
            redirect_to root_path
          end
        end
      end
    end
  end
end
