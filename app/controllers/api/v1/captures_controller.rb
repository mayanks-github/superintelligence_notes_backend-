module Api
  module V1
    class CapturesController < ApplicationController
      rescue_from Google::Error, with: :google_error
      rescue_from ArgumentError, with: :bad_filter

      def index
        captures = filtered_captures
        render json: { captures: captures.map { |capture| Payloads.capture(capture) } }
      end

      def create
        source = Source.visible.find_by(key: paste_params[:source])
        return render json: { error: "Choose a source." }, status: :unprocessable_entity unless source&.supports_manual_paste

        video_id = nil
        video_url = nil
        video_title = nil
        if source.supports_watch
          video_id = extract_video_id(paste_params[:video_url])
          return render json: { error: "A YouTube URL is required." }, status: :unprocessable_entity if video_id.blank?

          video_url = "https://www.youtube.com/watch?v=#{video_id}"
          video_title = paste_params[:title]
        end

        note = Google::DocsStore.new(current_user).create(
          title: paste_params[:title],
          video_id: video_id,
          video_title: video_title,
          video_url: video_url,
          summary_text: paste_params[:summary_text],
          source: source.key,
          captured_at: Time.current.iso8601,
          sections: []
        )
        capture = Captures::Sync.call(
          current_user,
          note,
          origin: "manual",
          source: source,
          prefer_title: paste_params[:title]
        )
        render json: { capture: Payloads.capture(capture), note: note }, status: :created
      end

      private

      def filtered_captures
        scope = current_user.captures.includes(:source)
        if params[:source].present?
          scope = scope.joins(:source).where(sources: { key: params[:source] })
        end

        zone = ActiveSupport::TimeZone[current_user.profile&.timezone] || Time.zone
        if params[:saved_from].present?
          scope = scope.where("saved_at >= ?", bound_time(params[:saved_from], zone, :start))
        end
        if params[:saved_to].present?
          scope = scope.where("saved_at <= ?", bound_time(params[:saved_to], zone, :end))
        end

        params[:sort] == "saved_at_asc" ? scope.oldest : scope.newest
      end

      def bound_time(value, zone, edge)
        date = Date.iso8601(value.to_s)
        time = zone.local(date.year, date.month, date.day)
        edge == :end ? time.end_of_day : time.beginning_of_day
      end

      def paste_params
        params.require(:capture).permit(:source, :title, :summary_text, :video_url)
      end

      def extract_video_id(url)
        url.to_s[/(?:v=|youtu\.be\/|\/shorts\/)([\w-]{6,})/, 1]
      end

      def google_error(error)
        render json: { error: error.message }, status: :unprocessable_entity
      end

      def bad_filter(error)
        render json: { error: error.message }, status: :unprocessable_entity
      end
    end
  end
end
