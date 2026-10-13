class JsonWebToken
  SECRET_KEY = ENV.fetch("JWT_SECRET") { Rails.application.secret_key_base }

  def self.encode(payload, exp = 7.days.from_now)
    payload = payload.dup
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY, "HS256")
  end

  def self.decode(token)
    body = JWT.decode(token, SECRET_KEY, true, algorithm: "HS256").first
    HashWithIndifferentAccess.new(body)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end
