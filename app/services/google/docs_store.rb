module Google
  class DocsStore
    SOURCES = %w[gemini-youtube manual gemini-api youtube gemini chatgpt grok claude].freeze
    LIBRARY_VIDEO_ID = "library"
    DRIVE = "https://www.googleapis.com/drive/v3/files"
    FILE_FIELDS = "id,name,description,createdTime,modifiedTime,webViewLink,appProperties"

    def initialize(user)
      @user = user
    end

    def list(video_id: nil)
      query = "mimeType = 'application/vnd.google-apps.document' and trashed = false and appProperties has { key='superintelligence' and value='1' }"
      if video_id.present?
        raise Error, "Invalid video_id" unless video_id.match?(/\A[\w-]{1,64}\z/)

        query += " and appProperties has { key='video_id' and value='#{video_id}' }"
      end

      list_files(query).map { |file| summary_json(file) }
    end

    def list_videos
      notes = list
      notes
        .group_by { |note| note[:video_id].presence || "unknown" }
        .map do |video_id, video_notes|
          sorted = video_notes.sort_by { |note| note[:created_at].to_s }.reverse
          primary = sorted.find { |note| note[:video_title].present? } || sorted.first
          {
            video_id: video_id,
            video_title: primary[:video_title].presence || video_id,
            video_url: primary[:video_url] || (
              library_video?(video_id) || video_id == "unknown" ? nil : "https://www.youtube.com/watch?v=#{video_id}"
            ),
            thumbnail_url: library_video?(video_id) || video_id == "unknown" ? nil : "https://i.ytimg.com/vi/#{video_id}/hqdefault.jpg",
            notes_count: sorted.size,
            notes: sorted.map { |note| note.slice(:id, :title, :source, :captured_at, :created_at, :web_view_link) },
            latest_captured_at: sorted.first[:captured_at] || sorted.first[:created_at]
          }
        end
        .sort_by { |video| video[:latest_captured_at].to_s }
        .reverse
    end

    def find_video(video_id)
      raise Error, "Invalid video_id" unless video_id.to_s.match?(/\A[\w-]{1,64}\z/)

      videos = list_videos
      video = videos.find { |item| item[:video_id] == video_id }
      raise NotFound, "Video not found" unless video

      video
    end

    def find(id)
      file = drive_file(id)
      document = Http.get_json("https://docs.googleapis.com/v1/documents/#{id}", token: token)
      text = extract_text(document)
      note_json(NoteDocument.parse(text), file)
    end

    def create(attributes)
      note = normalize(attributes)
      parent_id = video_folder_id(note[:video_id], note[:video_title])
      file = Http.post_json(
        DRIVE,
        token: token,
        params: { fields: FILE_FIELDS },
        body: file_metadata(note).merge(parents: [ parent_id ])
      )
      begin
        write_body(file["id"], NoteDocument.render(note))
      rescue Error
        Http.patch_json("#{DRIVE}/#{file["id"]}", token: token, params: { fields: "id" }, body: { trashed: true })
        raise
      end
      note_json(note, file)
    end

    def update(id, attributes)
      existing = find(id)
      note = normalize(existing.symbolize_keys.merge(attributes.to_h.symbolize_keys.compact))
      file = Http.patch_json(
        "#{DRIVE}/#{id}",
        token: token,
        params: { fields: FILE_FIELDS },
        body: file_metadata(note)
      )
      write_body(id, NoteDocument.render(note))
      note_json(note, file)
    end

    def destroy(id)
      drive_file(id)
      Http.patch_json(
        "#{DRIVE}/#{id}",
        token: token,
        params: { fields: "id" },
        body: { trashed: true }
      )
    end

    private

    def token
      @user.google_access_token!
    end

    def folder_id
      return @folder_id if @folder_id

      stored_id = @user.google_docs_folder_id
      if stored_id.present? && stored_id.match?(/\A[\w-]+\z/)
        begin
          folder = drive_get("#{DRIVE}/#{stored_id}", fields: "id,trashed")
          return @folder_id = stored_id unless folder["trashed"]
        rescue NotFound
          nil
        end
        @user.update!(google_docs_folder_id: nil)
      end

      found = drive_get(
        DRIVE,
        q: "mimeType = 'application/vnd.google-apps.folder' and trashed = false and appProperties has { key='superintelligence' and value='folder' }",
        fields: "files(id)",
        pageSize: 1
      )
      id = found.dig("files", 0, "id")
      id ||= Http.post_json(
        DRIVE,
        token: token,
        params: { fields: "id" },
        body: {
          name: "Superintelligence Notes",
          mimeType: "application/vnd.google-apps.folder",
          appProperties: { superintelligence: "folder" }
        }
      )["id"]

      @user.update!(google_docs_folder_id: id)
      @folder_id = id
    end

    def file_metadata(note)
      {
        name: note_file_name(note),
        mimeType: "application/vnd.google-apps.document",
        description: sanitize_plain_text(note[:summary_text]).slice(0, 1000),
        appProperties: {
          superintelligence: "1",
          video_id: note[:video_id].to_s.slice(0, 120),
          video_title: sanitize_app_property(note[:video_title], 120),
          source: note[:source].to_s.slice(0, 120),
          # Avoid ":" in values — Drive rejects some URL/ISO forms as invalid arguments.
          captured_at: note[:captured_at].to_s.gsub(/[^0-9TZX.-]/i, "").slice(0, 120)
        }
      }
    end

    def note_file_name(note)
      custom = note[:title].to_s.gsub(/[\r\n]+/, " ").strip
      return custom.slice(0, 200) if custom.present?

      time = parse_time(note[:captured_at])
      stamp = time.strftime("%Y-%m-%d %H.%M")
      source = note[:source].to_s.presence || "note"
      "#{stamp} · #{source}".gsub(/[\r\n]+/, " ").slice(0, 200)
    end

    def video_folder_id(video_id, video_title)
      raise Error, "Invalid video_id" unless video_id.to_s.match?(/\A[\w-]{1,64}\z/)

      found = drive_get(
        DRIVE,
        q: "'#{folder_id}' in parents and mimeType = 'application/vnd.google-apps.folder' and trashed = false and appProperties has { key='video_id' and value='#{video_id}' }",
        fields: "files(id)",
        pageSize: 1
      )
      id = found.dig("files", 0, "id")
      return id if id.present?

      title = sanitize_plain_text(video_title).presence || video_id
      folder_name = "#{title} [#{video_id}]".slice(0, 200)
      Http.post_json(
        DRIVE,
        token: token,
        params: { fields: "id" },
        body: {
          name: folder_name,
          mimeType: "application/vnd.google-apps.folder",
          parents: [ folder_id ],
          appProperties: {
            superintelligence: "video_folder",
            video_id: video_id.to_s.slice(0, 120),
            video_title: sanitize_app_property(title, 120)
          }
        }
      )["id"]
    end

    def list_files(query)
      files = []
      page_token = nil
      loop do
        response = drive_get(
          DRIVE,
          q: query,
          fields: "nextPageToken,files(#{FILE_FIELDS})",
          orderBy: "createdTime desc",
          pageSize: 100,
          pageToken: page_token
        )
        files.concat(Array(response["files"]))
        page_token = response["nextPageToken"]
        break if page_token.blank?
      end
      files
    end

    def sanitize_app_property(value, max = 120)
      value.to_s.gsub(/[^0-9A-Za-z\s\-._]/i, " ").squeeze(" ").strip.slice(0, max)
    end

    def parse_time(value)
      Time.iso8601(value.to_s)
    rescue ArgumentError, TypeError
      Time.current
    end

    def write_body(id, text)
      document = Http.get_json("https://docs.googleapis.com/v1/documents/#{id}", token: token)
      end_index = document.dig("body", "content")&.last&.dig("endIndex").to_i
      safe_text = sanitize_docs_text(text)
      requests = []
      requests << { deleteContentRange: { range: { startIndex: 1, endIndex: end_index - 1 } } } if end_index > 2
      requests << { insertText: { location: { index: 1 }, text: safe_text } }
      Http.post_json(
        "https://docs.googleapis.com/v1/documents/#{id}:batchUpdate",
        token: token,
        body: { requests: requests }
      )
    end

    def sanitize_docs_text(text)
      # Docs API only allows tab/newline among C0 controls.
      text.to_s.gsub("\r\n", "\n").gsub("\r", "\n").gsub(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/, "")
    end

    def sanitize_plain_text(text)
      sanitize_docs_text(text).gsub(/\s+/, " ").strip
    end

    def extract_text(document)
      Array(document.dig("body", "content")).flat_map do |element|
        Array(element.dig("paragraph", "elements")).map { |item| item.dig("textRun", "content").to_s }
      end.join
    end

    def drive_file(id)
      raise NotFound, "Note not found" unless id.to_s.match?(/\A[\w-]+\z/)

      drive_get("#{DRIVE}/#{id}", fields: FILE_FIELDS)
    end

    def drive_get(url, params)
      Http.get_json(url, token: token, params: params)
    end

    def normalize(attributes)
      attributes = attributes.to_h.symbolize_keys
      video_id = attributes[:video_id].to_s.strip
      summary = attributes[:summary_text].to_s
      source = attributes[:source].presence || "gemini-youtube"
      sections = attributes[:sections] || []

      raise Error, "summary_text is required" if summary.blank?
      raise Error, "invalid source" unless SOURCES.include?(source)
      raise Error, "sections must be an array" unless sections.is_a?(Array)

      if video_id.blank?
        video_id = LIBRARY_VIDEO_ID
        video_url = attributes[:video_url].presence
        video_title = attributes[:video_title].presence || "Library"
      else
        raise Error, "Invalid video_id" unless video_id.match?(/\A[\w-]{1,64}\z/)

        video_url = attributes[:video_url].presence || "https://www.youtube.com/watch?v=#{video_id}"
        video_title = attributes[:video_title].presence || video_id
      end

      captured_at = attributes[:captured_at].presence || Time.current.iso8601
      {
        title: attributes[:title].presence,
        video_id: video_id,
        video_title: video_title,
        video_url: video_url,
        summary_text: summary,
        source: source,
        sections: sections.map { |section| section.to_h.symbolize_keys },
        captured_at: captured_at.respond_to?(:iso8601) ? captured_at.iso8601 : captured_at.to_s
      }
    end

    def library_video?(video_id)
      video_id.to_s == LIBRARY_VIDEO_ID
    end

    def summary_json(file)
      props = file["appProperties"] || {}
      video_id = props["video_id"]
      {
        id: file["id"],
        title: file["name"],
        video_id: video_id,
        video_title: props["video_title"].presence || file["name"],
        video_url: library_video?(video_id) ? nil : (
          props["video_url"].presence || (video_id.present? ? "https://www.youtube.com/watch?v=#{video_id}" : nil)
        ),
        summary_text: file["description"].to_s,
        source: props["source"],
        sections: [],
        captured_at: props["captured_at"] || file["createdTime"],
        created_at: file["createdTime"],
        updated_at: file["modifiedTime"],
        web_view_link: file["webViewLink"]
      }
    end

    def note_json(note, file)
      note = note.to_h.symbolize_keys
      {
        id: file["id"],
        title: file["name"],
        video_id: note[:video_id],
        video_title: note[:video_title],
        video_url: note[:video_url],
        summary_text: note[:summary_text],
        source: note[:source],
        sections: note[:sections] || [],
        captured_at: note[:captured_at],
        created_at: file["createdTime"],
        updated_at: file["modifiedTime"],
        web_view_link: file["webViewLink"]
      }
    end
  end
end
