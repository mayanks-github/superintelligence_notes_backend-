require "prawn"
require "caracal"
require "tempfile"

module Notes
  class Export
    FORMATS = {
      "txt" => {
        content_type: "text/plain; charset=utf-8",
        extension: "txt"
      },
      "pdf" => {
        content_type: "application/pdf",
        extension: "pdf"
      },
      "docx" => {
        content_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        extension: "docx"
      }
    }.freeze

    def self.call(note, format)
      new(note, format).call
    end

    def initialize(note, format)
      @note = note.to_h.symbolize_keys
      @format = format.to_s.downcase
    end

    def call
      spec = FORMATS[@format]
      raise Google::Error, "Unsupported download format" unless spec

      {
        data: render_data,
        filename: "#{safe_basename}.#{spec[:extension]}",
        content_type: spec[:content_type]
      }
    end

    private

    def render_data
      case @format
      when "txt" then readable_text
      when "pdf" then render_pdf
      when "docx" then render_docx
      end
    end

    def readable_text
      Google::NoteDocument.readable_text(@note)
    end

    def render_pdf
      font_path = Rails.root.join("vendor/fonts/DejaVuSans.ttf")
      Prawn::Document.new(page_size: "LETTER", margin: 54) do |pdf|
        if File.exist?(font_path)
          pdf.font_families.update(
            "DejaVu" => {
              normal: font_path.to_s,
              bold: font_path.to_s
            }
          )
          pdf.font "DejaVu"
        else
          pdf.font "Helvetica"
        end

        readable_text.each_line do |line|
          content = line.chomp
          if content.blank?
            pdf.move_down 8
          else
            pdf.text content, size: 11, leading: 3
          end
        end
      end.render
    end

    def render_docx
      bullets = []
      file = Tempfile.new([ "note-export", ".docx" ])
      path = file.path
      file.close

      begin
        Caracal::Document.save(path) do |docx|
          flush_bullets = lambda do
            return if bullets.empty?

            items = bullets.dup
            bullets.clear
            docx.ul do
              items.each { |item| li item }
            end
          end

          readable_text.each_line do |line|
            content = line.chomp
            if content.start_with?("- ")
              bullets << content.delete_prefix("- ")
              next
            end

            flush_bullets.call
            if content.blank?
              docx.p
            else
              docx.p content
            end
          end

          flush_bullets.call
        end

        File.binread(path)
      ensure
        File.delete(path) if File.exist?(path)
      end
    end

    def display_title
      @note[:title].presence || @note[:video_title].presence || "Note"
    end

    def safe_basename
      display_title
        .to_s
        .gsub(/[^\w\s\-.]/u, "")
        .squeeze(" ")
        .strip
        .presence || "note"
    end
  end
end
