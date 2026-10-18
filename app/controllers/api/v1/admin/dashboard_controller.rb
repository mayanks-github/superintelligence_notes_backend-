module Api
  module V1
    module Admin
      class DashboardController < BaseController
        def show
          render json: {
            dashboard: {
              users: User.count,
              premium_users: User.where(plan_tier: "premium").count,
              captures_today: Capture.where(saved_at: Time.current.beginning_of_day..Time.current.end_of_day).count,
              premium_feature_enabled: AppSetting.premium_feature_enabled?
            }
          }
        end
      end
    end
  end
end
