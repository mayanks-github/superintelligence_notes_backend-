require "cgi"
require "net/http"
require "uri"
require "stringio"

module Avatars
  class Generator
    DICEBEAR = "https://api.dicebear.com/9.x/notionists/svg".freeze
    UI_AVATARS = "https://ui-avatars.com/api/".freeze

    def self.attach_generated!(profile, force: false)
      return if profile.avatar.attached? && !force

      svg = fetch(dicebear_url(profile.user.google_uid))
      if svg.present?
        profile.avatar.attach(
          io: StringIO.new(svg),
          filename: "avatar.svg",
          content_type: "image/svg+xml"
        )
        profile.update!(avatar_source: "generated")
        return
      end

      png = fetch(initials_url(profile))
      return if png.blank?

      profile.avatar.attach(
        io: StringIO.new(png),
        filename: "avatar.png",
        content_type: "image/png"
      )
      profile.update!(avatar_source: "generated")
    end

    def self.dicebear_url(seed)
      "#{DICEBEAR}?seed=#{CGI.escape(seed.to_s)}&backgroundColor=1a222c"
    end

    def self.initials_url(profile)
      name = [ profile.first_name, profile.last_name ].compact_blank.join(" ")
      "#{UI_AVATARS}?name=#{CGI.escape(name)}&background=1a222c&color=eef3f8&size=256&format=png"
    end

    def self.fetch(url, limit = 1_000_000)
      uri = URI(url)
      response = request(uri)
      response = request(URI(response["location"])) if response.is_a?(Net::HTTPRedirection) && response["location"].present?
      return nil unless response.is_a?(Net::HTTPSuccess)

      body = response.body.to_s
      return nil if body.bytesize > limit || body.blank?

      body
    rescue StandardError => error
      Rails.logger.warn("Avatar download failed: #{error.message}")
      nil
    end

    def self.request(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 3
      http.read_timeout = 5
      http.request(Net::HTTP::Get.new(uri))
    end
  end
end
