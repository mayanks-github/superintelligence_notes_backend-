require "uri"

module Google
  class Oauth
    SCOPES = [
      "openid",
      "email",
      "profile",
      "https://www.googleapis.com/auth/drive.file"
    ].freeze

    def self.authorization_url(state:)
      query = {
        client_id: Configuration.client_id,
        redirect_uri: Configuration.redirect_uri,
        response_type: "code",
        scope: SCOPES.join(" "),
        access_type: "offline",
        prompt: "consent",
        include_granted_scopes: "true",
        state: state
      }
      "https://accounts.google.com/o/oauth2/v2/auth?#{URI.encode_www_form(query)}"
    end

    def self.exchange_code(code)
      Http.post_form(
        "https://oauth2.googleapis.com/token",
        code: code,
        client_id: Configuration.client_id,
        client_secret: Configuration.client_secret,
        redirect_uri: Configuration.redirect_uri,
        grant_type: "authorization_code"
      )
    end

    def self.refresh(refresh_token)
      Http.post_form(
        "https://oauth2.googleapis.com/token",
        refresh_token: refresh_token,
        client_id: Configuration.client_id,
        client_secret: Configuration.client_secret,
        grant_type: "refresh_token"
      )
    end

    def self.userinfo(access_token)
      Http.get_json("https://www.googleapis.com/oauth2/v3/userinfo", token: access_token)
    end

    def self.sign_state(return_to)
      verifier.generate({ "return_to" => return_to, "exp" => 10.minutes.from_now.to_i }, purpose: :google_oauth)
    end

    def self.read_state(state)
      payload = verifier.verified(state, purpose: :google_oauth)
      raise Error, "Google sign-in expired. Try again." if payload.blank? || payload["exp"].to_i < Time.current.to_i

      return_to = payload["return_to"].to_s
      raise Error, "Invalid return target." unless allowed_return_to?(return_to)

      return_to
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      raise Error, "Google sign-in expired. Try again."
    end

    def self.allowed_return_to?(url)
      uri = URI.parse(url)
      return false unless uri.is_a?(URI::HTTP) && uri.query.blank? && uri.fragment.blank?

      origin = "#{uri.scheme}://#{uri.host}"
      origin = "#{origin}:#{uri.port}" if uri.port && uri.port != uri.default_port
      return true if Configuration.frontend_origins.include?(origin) && uri.path == "/auth/callback"
      return true if uri.scheme == "https" && uri.host&.end_with?(".chromiumapp.org") && (uri.path.blank? || uri.path == "/")

      false
    rescue URI::InvalidURIError
      false
    end

    def self.with_query(url, params)
      uri = URI.parse(url)
      uri.query = URI.encode_www_form(params)
      uri.to_s
    end

    def self.verifier
      Rails.application.message_verifier("google-oauth")
    end
  end
end
