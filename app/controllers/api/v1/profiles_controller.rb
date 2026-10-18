module Api
  module V1
    class ProfilesController < ApplicationController
      AVATAR_TYPES = %w[image/jpeg image/png image/webp].freeze

      def show
        render json: { profile: Payloads.profile(profile_record) }
      end

      def update
        profile_record.update!(profile_params)
        current_user.update!(name: display_name)
        render json: { user: Payloads.user(current_user.reload) }
      end

      def upload_avatar
        file = params[:avatar]
        return render json: { error: "Choose an image." }, status: :unprocessable_entity if file.blank?
        unless AVATAR_TYPES.include?(file.content_type)
          return render json: { error: "Upload a JPEG, PNG, or WebP image." }, status: :unprocessable_entity
        end
        if file.size > 2.megabytes
          return render json: { error: "Image must be 2 MB or smaller." }, status: :unprocessable_entity
        end

        profile_record.avatar.attach(file)
        profile_record.update!(avatar_source: "upload")
        render json: { user: Payloads.user(current_user.reload) }
      end

      def destroy_avatar
        profile_record.update!(avatar_source: "generated")
        Avatars::Generator.attach_generated!(profile_record, force: true)
        render json: { user: Payloads.user(current_user.reload) }
      end

      private

      def profile_record
        current_user.profile || current_user.create_profile!(
          first_name: current_user.name.to_s.split(/\s+/, 2).first.presence || current_user.email,
          last_name: current_user.name.to_s.split(/\s+/, 2).second,
          email: current_user.email,
          timezone: "Asia/Kolkata",
          avatar_source: "generated"
        )
      end

      def profile_params
        params.require(:profile).permit(:first_name, :last_name, :phone, :timezone, :bio)
      end

      def display_name
        [ profile_record.first_name, profile_record.last_name ].compact_blank.join(" ").presence || current_user.email
      end
    end
  end
end
