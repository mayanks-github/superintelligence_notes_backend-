module Api
  module V1
    module Admin
      class UsersController < BaseController
        def index
          scope = User.order(created_at: :desc)
          query = params[:q].to_s.strip
          if query.present?
            like = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
            scope = scope.left_joins(:profile).where(
              "users.email ILIKE :q OR users.name ILIKE :q OR profiles.first_name ILIKE :q OR profiles.last_name ILIKE :q",
              q: like
            )
          end

          users = scope.limit(100).to_a
          counts = Capture.where(user_id: users.map(&:id)).group(:user_id).count
          render json: {
            users: users.map { |user| user_json(user, counts[user.id].to_i) }
          }
        end

        def update_premium
          user = User.find(params[:id])
          enabled = cast_enabled!
          return if performed?

          user.update!(plan_tier: enabled ? "premium" : "free")
          render json: { user: user_json(user, user.captures.count) }
        end

        private

        def user_json(user, captures_count)
          {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
            plan_tier: user.plan_tier,
            premium_active: user.premium?,
            created_at: user.created_at,
            captures_count: captures_count
          }
        end
      end
    end
  end
end
