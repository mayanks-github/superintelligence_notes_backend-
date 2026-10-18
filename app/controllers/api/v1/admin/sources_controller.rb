module Api
  module V1
    module Admin
      class SourcesController < BaseController
        def index
          render json: { sources: Source.ordered.map { |source| Payloads.source(source) } }
        end

        def update
          Array(params[:sources]).each do |row|
            source = Source.find_by!(key: row[:key] || row["key"])
            source.update!(
              enabled: row.key?(:enabled) || row.key?("enabled") ? ActiveModel::Type::Boolean.new.cast(row[:enabled] || row["enabled"]) : source.enabled,
              position: (row[:position] || row["position"] || source.position).to_i
            )
          end
          render json: { sources: Source.ordered.map { |source| Payloads.source(source) } }
        end
      end
    end
  end
end
