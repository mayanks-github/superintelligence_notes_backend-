module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_request, only: %i[google callback]

      def google
        return_to = params[:return_to].to_s
        unless Google::Oauth.allowed_return_to?(return_to)
          return render plain: "Invalid return_to", status: :bad_request
        end
        unless Google::Configuration.configured?
          return render plain: "Set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET in superintelligence_notes_backend/.env, then restart Rails.", status: :service_unavailable
        end

        redirect_to Google::Oauth.authorization_url(state: Google::Oauth.sign_state(return_to)), allow_other_host: true
      end

      def callback
        return_to = Google::Oauth.read_state(params[:state])
        if params[:error].present?
          return redirect_to Google::Oauth.with_query(return_to, error: params[:error]), allow_other_host: true
        end

        raise Google::Error, "Missing authorization code." if params[:code].blank?

        tokens = Google::Oauth.exchange_code(params[:code])
        profile = Google::Oauth.userinfo(tokens.fetch("access_token"))
        user = User.from_google!(profile, tokens)
        redirect_to Google::Oauth.with_query(return_to, token: JsonWebToken.encode(user_id: user.id)), allow_other_host: true
      rescue Google::Error => error
        if return_to.present?
          redirect_to Google::Oauth.with_query(return_to, error: error.message), allow_other_host: true
        else
          render plain: error.message, status: :bad_request
        end
      end

      def me
        render json: { user: Payloads.user(current_user) }
      end
    end
  end
end
