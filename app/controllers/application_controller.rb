class ApplicationController < ActionController::API
  before_action :set_active_storage_url_options
  before_action :authenticate_request

  attr_reader :current_user

  private

  def set_active_storage_url_options
    ActiveStorage::Current.url_options = {
      protocol: request.protocol,
      host: request.host,
      port: request.port
    }
  end

  def authenticate_request
    header = request.headers["Authorization"]
    token = header&.split(" ")&.last
    payload = JsonWebToken.decode(token)

    @current_user = User.find_by(id: payload[:user_id]) if payload

    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
  end
end
