module Api
  module V1
    class VideosController < ApplicationController
      rescue_from Google::Error, with: :google_error
      rescue_from Google::NotFound, with: :video_not_found

      def index
        render json: { videos: docs.list_videos }
      end

      def show
        render json: { video: docs.find_video(params[:id]) }
      end

      private

      def docs
        @docs ||= Google::DocsStore.new(current_user)
      end

      def google_error(error)
        render json: { error: error.message }, status: :unprocessable_entity
      end

      def video_not_found
        render json: { error: "Video not found" }, status: :not_found
      end
    end
  end
end
