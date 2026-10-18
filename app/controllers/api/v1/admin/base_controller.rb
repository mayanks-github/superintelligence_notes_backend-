module Api
  module V1
    module Admin
      class BaseController < ApplicationController
        before_action :require_admin

        private

        def require_admin
          render json: { error: "Forbidden" }, status: :forbidden unless current_user.admin?
        end

        def cast_enabled!
          return ActiveModel::Type::Boolean.new.cast(params[:enabled]) if params.key?(:enabled)

          render json: { error: "enabled is required" }, status: :unprocessable_entity
          nil
        end
      end
    end
  end
end
