module Api
  module V1
    module Payloads
      module_function

      def user(user)
        {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          plan_tier: user.plan_tier,
          premium_active: user.premium?,
          profile: user.profile ? profile(user.profile) : nil
        }
      end

      def profile(record)
        {
          first_name: record.first_name,
          last_name: record.last_name,
          email: record.email,
          phone: record.phone,
          timezone: record.timezone,
          bio: record.bio,
          avatar_source: record.avatar_source,
          avatar_url: avatar_url(record)
        }
      end

      def source(record)
        {
          key: record.key,
          name: record.name,
          kind: record.kind,
          brand_color: record.brand_color,
          supports_watch: record.supports_watch,
          supports_manual_paste: record.supports_manual_paste,
          enabled: record.enabled,
          position: record.position
        }
      end

      def capture(record)
        {
          id: record.id,
          title: record.title,
          summary_text: record.summary_text,
          origin: record.origin,
          google_doc_id: record.google_doc_id,
          external_url: record.external_url,
          video_id: record.video_id,
          video_url: record.video_url,
          video_title: record.video_title,
          thumbnail_url: record.thumbnail_url,
          saved_at: record.saved_at,
          storage: record.storage,
          web_view_link: record.google_doc_id.present? ? "https://docs.google.com/document/d/#{record.google_doc_id}/edit" : nil,
          source: source(record.source)
        }
      end

      def extension_site(site, preference)
        {
          key: site.key,
          name: site.name,
          match_pattern: site.match_pattern,
          aliases: site.aliases,
          catalog_enabled: site.enabled,
          default_enabled: site.default_enabled,
          enabled: preference&.enabled || false
        }
      end

      def avatar_url(record)
        return nil unless record.avatar.attached?

        Rails.application.routes.url_helpers.rails_blob_url(record.avatar, **ActiveStorage::Current.url_options)
      rescue StandardError
        nil
      end
    end
  end
end
