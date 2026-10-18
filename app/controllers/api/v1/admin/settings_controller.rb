module Api
  module V1
    module Admin
      class SettingsController < BaseController
        def show
          render json: { premium_feature_enabled: AppSetting.premium_feature_enabled? }
        end

        def update
          raw = params.key?(:premium_feature_enabled) ? params[:premium_feature_enabled] : params[:enabled]
          if raw.nil? && !params.key?(:premium_feature_enabled) && !params.key?(:enabled)
            return render json: { error: "premium_feature_enabled is required" }, status: :unprocessable_entity
          end

          AppSetting.set_premium_feature_enabled!(raw)
          render json: { premium_feature_enabled: AppSetting.premium_feature_enabled? }
        end
      end
    end
  end
end
