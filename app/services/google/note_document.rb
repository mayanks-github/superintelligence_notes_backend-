require "base64"
require "json"

module Google
  class NoteDocument
    START_MARKER = "<<<SUPERINTELLIGENCE>>>".freeze
    END_MARKER = "<<<END SUPERINTELLIGENCE>>>".freeze

    def self.readable_text(note)
      note = note.to_h.symbolize_keys
      title = note[:title].presence || note[:video_title].presence
      lines = []
      lines << title.to_s if title.present?
      lines << "" if title.present?
      lines << note[:video_title].to_s if note[:video_title].present? && note[:video_title] != title
      lines << note[:video_url].to_s if note[:video_url].present?
      lines << "Source: #{note[:source]}" if note[:source].present?
      lines << "Captured: #{note[:captured_at]}" if note[:captured_at].present?
      lines << ""
      lines << "Summary"
      lines << note[:summary_text].to_s

      sections = Array(note[:sections])
      if sections.any?
        lines << ""
        lines << "Sections"
        sections.each do |section|
          section = section.to_h.symbolize_keys
          heading = section[:heading].presence || "Section"
          timestamp = section[:timestamp].presence
          lines << ""
          lines << [ heading, timestamp ].compact.join(" · ")
          Array(section[:bullets]).each do |bullet|
            lines << "- #{bullet}"
          end
        end
      end

      lines.join("\n").strip + "\n"
    end

    def self.render(note)
      note = note.to_h.symbolize_keys
      sections = Array(note[:sections])
      payload = {
        title: note[:title],
        video_id: note[:video_id],
        video_title: note[:video_title],
        video_url: note[:video_url],
        summary_text: note[:summary_text],
        source: note[:source],
        sections: sections,
        captured_at: note[:captured_at]
      }
      encoded = Base64.strict_encode64(JSON.generate(payload))

      [
        readable_text(note).rstrip,
        "",
        "App data used by Superintelligence Notes to reopen this note.",
        START_MARKER,
        encoded,
        END_MARKER,
        ""
      ].join("\n")
    end

    def self.parse(text)
      start_at = text.to_s.rindex(START_MARKER)
      end_at = text.to_s.rindex(END_MARKER)
      raise Error, "This Google Doc is missing Superintelligence Notes data." if start_at.nil? || end_at.nil? || end_at < start_at

      encoded = text[(start_at + START_MARKER.length)...end_at].gsub(/\s+/, "")
      JSON.parse(Base64.strict_decode64(encoded))
    rescue JSON::ParserError, ArgumentError
      raise Error, "Could not read this Google Doc."
    end
  end
end
