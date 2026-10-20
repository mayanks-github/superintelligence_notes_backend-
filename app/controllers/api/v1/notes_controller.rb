module Api
  module V1
    class NotesController < ApplicationController
      rescue_from Google::Error, with: :google_error
      rescue_from Google::NotFound, with: :note_not_found

      def index
        notes = docs.list(video_id: params[:video_id])
        render json: { notes: notes }
      end

      def show
        render json: { note: docs.find(params[:id]) }
      end

      def create
        note = docs.create(note_attributes)
        Captures::Sync.call(current_user, note, origin: "extension")
        render json: { note: note }, status: :created
      end

      def update
        note = docs.update(params[:id], note_attributes)
        Captures::Sync.call(
          current_user,
          note,
          origin: "extension",
          prefer_title: params.dig(:note, :title)
        )
        render json: { note: note }
      end

      def destroy
        docs.destroy(params[:id])
        Captures::Sync.destroy_for(current_user, params[:id])
        head :no_content
      end

      def download
        note = docs.find(params[:id])
        export = Notes::Export.call(note, params[:format])
        send_data(
          export[:data],
          filename: export[:filename],
          type: export[:content_type],
          disposition: "attachment"
        )
      end

      private

      def docs
        @docs ||= Google::DocsStore.new(current_user)
      end

      def note_attributes
        permitted = params.require(:note).permit(
          :title,
          :video_id,
          :video_title,
          :video_url,
          :summary_text,
          :source,
          :captured_at
        ).to_h
        if params[:note].key?(:sections)
          permitted["sections"] = Array(params[:note][:sections]).map do |section|
            section.permit(:heading, :timestamp, bullets: []).to_h
          end
        end
        permitted
      end

      def google_error(error)
        render json: { error: error.message }, status: :unprocessable_entity
      end

      def note_not_found
        render json: { error: "Note not found" }, status: :not_found
      end
    end
  end
end
