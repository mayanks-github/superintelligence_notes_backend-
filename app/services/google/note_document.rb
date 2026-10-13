require "base64"
require "json"

module Google
  class NoteDocument
    START_MARKER = "<<<SUPERINTELLIGENCE>>>".freeze
    END_MARKER = "<<<END SUPERINTELLIGENCE>>>".freeze

    def self.render(note)
      lines = [
        note[:video_title].to_s,
        "",
        note[:video_url].to_s,
        "Source: #{note[:source]}",
        "Captured: #{note[:captured_at]}",
        "",
        "Summary",
        note[:summary_text].to_s
      ]

      sections = Array(note[:sections])
      if sections.any?
        lines << ""
        lines << "Sections"
        sections.each do |section|
          heading = section[:heading].presence || section["heading"].presence || "Section"
          timestamp = section[:timestamp].presence || section["timestamp"].presence
          lines << ""
          lines << [ heading, timestamp ].compact.join(" · ")
          Array(section[:bullets] || section["bullets"]).each do |bullet|
            lines << "- #{bullet}"
          end
        end
      end

      payload = {
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
        lines.join("\n"),
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
