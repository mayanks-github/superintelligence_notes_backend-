require "json"
require "net/http"
require "uri"

module Google
  class Http
    def self.get_json(url, token:, params: nil)
      request_json(:get, url, token: token, params: params)
    end

    def self.post_json(url, token: nil, body: nil, params: nil)
      request_json(:post, url, token: token, body: body, params: params)
    end

    def self.patch_json(url, token:, body:, params: nil)
      request_json(:patch, url, token: token, body: body, params: params)
    end

    def self.post_form(url, form)
      uri = URI(url)
      response = perform(Net::HTTP::Post.new(uri), uri) do |request|
        request.set_form_data(form)
      end
      parse!(response)
    end

    def self.request_json(method, url, token: nil, body: nil, params: nil)
      uri = URI(url)
      uri.query = URI.encode_www_form(params.compact) if params.present?
      klass = Net::HTTP.const_get(method.to_s.capitalize)
      response = perform(klass.new(uri), uri) do |request|
        request["Authorization"] = "Bearer #{token}" if token
        if body
          request["Content-Type"] = "application/json"
          request.body = JSON.generate(body)
        end
      end
      parse!(response)
    end

    def self.perform(request, uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = 30
      yield request
      http.request(request)
    end

    def self.parse!(response)
      parsed = response.body.to_s.empty? ? {} : JSON.parse(response.body)
      return parsed if response.is_a?(Net::HTTPSuccess)

      message = parsed["error_description"] || parsed.dig("error", "message") || parsed["error"] || response.message
      error_class = response.code == "404" ? NotFound : Error
      raise error_class, message.to_s
    rescue JSON::ParserError
      raise Error, response.message
    end
  end
end
