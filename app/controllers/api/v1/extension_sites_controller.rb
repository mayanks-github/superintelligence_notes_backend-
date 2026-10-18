module Api
  module V1
    class ExtensionSitesController < ApplicationController
      def index
        current_user.ensure_extension_sites!
        preferences = current_user.user_extension_sites.includes(:extension_site).index_by(&:extension_site_id)
        sites = ExtensionSite.ordered.map do |site|
          Payloads.extension_site(site, preferences[site.id])
        end
        render json: { sites: sites }
      end

      def update
        site = ExtensionSite.find_by(key: params[:key])
        return render json: { error: "Website not found" }, status: :not_found unless site

        enabled = ActiveModel::Type::Boolean.new.cast(params[:enabled])
        if enabled && !site.enabled
          return render json: { error: "#{site.name} is not available yet." }, status: :unprocessable_entity
        end

        preference = current_user.user_extension_sites.find_or_initialize_by(extension_site: site)
        preference.enabled = enabled
        preference.save!
        render json: { site: Payloads.extension_site(site, preference) }
      end
    end
  end
end
