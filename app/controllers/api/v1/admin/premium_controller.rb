module Api
  module V1
    module Admin
      class PremiumController < BaseController
        def bulk
          enabled = cast_enabled!
          return if performed?

          User.update_all(plan_tier: enabled ? "premium" : "free", updated_at: Time.current)
          render json: {
            premium_users: User.where(plan_tier: "premium").count,
            users: User.count
          }
        end
      end
    end
  end
end
