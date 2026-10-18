module Api
  module V1
    module Admin
      class ExtensionSitesController < BaseController
        def index
          render json: { sites: ExtensionSite.ordered.map { |site| site_json(site) } }
        end

        def update
          Array(params[:extension_sites]).each do |row|
            site = ExtensionSite.find_by!(key: row[:key] || row["key"])
            attrs = {}
            if row.key?(:enabled) || row.key?("enabled")
              attrs[:enabled] = ActiveModel::Type::Boolean.new.cast(row[:enabled] || row["enabled"])
            end
            if row.key?(:default_enabled) || row.key?("default_enabled")
              attrs[:default_enabled] = ActiveModel::Type::Boolean.new.cast(row[:default_enabled] || row["default_enabled"])
            end
            site.update!(attrs) if attrs.any?
          end
          render json: { sites: ExtensionSite.ordered.map { |site| site_json(site) } }
        end

        private

        def site_json(site)
          {
            key: site.key,
            name: site.name,
            match_pattern: site.match_pattern,
            aliases: site.aliases,
            enabled: site.enabled,
            default_enabled: site.default_enabled,
            position: site.position
          }
        end
      end
    end
  end
end
