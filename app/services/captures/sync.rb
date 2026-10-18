module Captures
  class Sync
    LIBRARY_VIDEO_ID = "library"

    def self.call(user, note, origin:, source: nil, prefer_title: nil)
      note = note.to_h.symbolize_keys
      doc_id = note[:id].to_s
      raise Google::Error, "Missing Google Doc id" if doc_id.blank?

      resolved = source || Source.find_by(key: source_key_for(note[:source])) || Source.find_by!(key: "gemini")
      capture = user.captures.find_or_initialize_by(google_doc_id: doc_id)
      video_id = real_video_id(note[:video_id])

      capture.source = resolved
      capture.origin = origin if capture.new_record?
      capture.title = prefer_title.presence || capture.title.presence || note[:video_title].presence || note[:title].presence || "Note"
      capture.summary_text = note[:summary_text].to_s
      capture.external_url = note[:external_url].presence
      capture.video_id = video_id
      capture.video_title = video_id.present? ? note[:video_title].presence : nil
      capture.video_url = video_id.present? ? note[:video_url].presence : nil
      capture.thumbnail_url = video_id.present? ? "https://i.ytimg.com/vi/#{video_id}/hqdefault.jpg" : nil
      capture.saved_at ||= parse_time(note[:captured_at])
      capture.storage = "google_docs"
      capture.save!
      capture
    end

    def self.destroy_for(user, google_doc_id)
      user.captures.find_by(google_doc_id: google_doc_id)&.destroy!
    end

    def self.source_key_for(raw)
      case raw.to_s
      when "gemini-youtube", "gemini-api", "gemini", "manual", ""
        "gemini"
      else
        raw.to_s
      end
    end

    def self.real_video_id(video_id)
      value = video_id.to_s
      return nil if value.blank? || value == LIBRARY_VIDEO_ID || value == "unknown"

      value
    end

    def self.parse_time(value)
      Time.iso8601(value.to_s)
    rescue ArgumentError, TypeError
      Time.current
    end
  end
end
