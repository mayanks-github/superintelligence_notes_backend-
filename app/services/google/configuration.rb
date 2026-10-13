module Google
  class Configuration
    def self.client_id
      ENV["GOOGLE_CLIENT_ID"].presence
    end

    def self.client_secret
      ENV["GOOGLE_CLIENT_SECRET"].presence
    end

    def self.redirect_uri
      ENV.fetch("GOOGLE_REDIRECT_URI", "http://localhost:3000/api/v1/auth/google/callback")
    end

    def self.frontend_origins
      ENV.fetch("FRONTEND_ORIGINS", "http://localhost:5173,http://127.0.0.1:5173").split(",").map(&:strip)
    end

    def self.configured?
      client_id.present? && client_secret.present?
    end
  end
end
