sources = [
  { key: "youtube", name: "YouTube", kind: "video", host: "www.youtube.com", brand_color: "#ff0033", supports_watch: true, supports_manual_paste: true, extension_capturable: true, position: 1 },
  { key: "gemini", name: "Gemini", kind: "assistant", host: "gemini.google.com", brand_color: "#8ab4f8", supports_watch: false, supports_manual_paste: true, extension_capturable: true, position: 2 },
  { key: "chatgpt", name: "ChatGPT", kind: "assistant", host: "chatgpt.com", brand_color: "#10a37f", supports_watch: false, supports_manual_paste: true, extension_capturable: false, position: 3 },
  { key: "grok", name: "Grok", kind: "assistant", host: "grok.com", brand_color: "#e6e6e6", supports_watch: false, supports_manual_paste: true, extension_capturable: false, position: 4 },
  { key: "claude", name: "Claude", kind: "assistant", host: "claude.ai", brand_color: "#d4a574", supports_watch: false, supports_manual_paste: true, extension_capturable: false, position: 5 }
]

sources.each do |row|
  source = Source.find_or_initialize_by(key: row[:key])
  source.update!(row.merge(enabled: source.enabled.nil? ? true : source.enabled))
end

sites = [
  { key: "youtube", name: "YouTube", match_pattern: "https://www.youtube.com/*", aliases: %w[yt], default_enabled: true, enabled: true, position: 1 },
  { key: "chatgpt", name: "ChatGPT", match_pattern: "https://chatgpt.com/*", aliases: [ "chat gpt", "openai" ], default_enabled: false, enabled: true, position: 2 },
  { key: "claude", name: "Claude", match_pattern: "https://claude.ai/*", aliases: [ "anthropic" ], default_enabled: false, enabled: true, position: 3 },
  { key: "gemini", name: "Gemini", match_pattern: "https://gemini.google.com/*", aliases: [ "google gemini" ], default_enabled: false, enabled: true, position: 4 },
  { key: "grok", name: "Grok", match_pattern: "https://grok.com/*", aliases: [ "xai", "x.ai" ], default_enabled: false, enabled: true, position: 5 }
]

sites.each do |row|
  site = ExtensionSite.find_or_initialize_by(key: row[:key])
  site.update!(row)
end

AppSetting.set_premium_feature_enabled!(true) unless AppSetting.exists?(key: AppSetting::PREMIUM_FEATURE)

User.find_each do |user|
  if user.profile.nil?
    parts = user.name.to_s.strip.split(/\s+/, 2)
    user.create_profile!(
      first_name: parts[0].presence || user.email,
      last_name: parts[1],
      email: user.email,
      timezone: "Asia/Kolkata",
      avatar_source: "generated"
    )
  else
    user.profile.update!(email: user.email)
  end

  user.ensure_extension_sites!
  user.promote_admin_from_env!
  begin
    Avatars::Generator.attach_generated!(user.profile)
  rescue StandardError => error
    puts "Avatar skipped for #{user.email}: #{error.message}"
  end
end
