# frozen_string_literal: true

class UploadsController < ApplicationController
  def create
    if params[:image].blank?
      render json: { error: "No image provided" }, status: :bad_request
      return
    end

    image = params[:image]

    # Validate file type
    unless image.content_type.start_with?("image/")
      render json: { error: "File must be an image" }, status: :bad_request
      return
    end

    # Validate file size (10MB)
    if image.size > 10.megabytes
      render json: { error: "Image must be smaller than 10MB" }, status: :bad_request
      return
    end

    begin
      # Create uploads directory if it doesn't exist
      uploads_dir = Rails.root.join("public", "uploads")
      FileUtils.mkdir_p(uploads_dir) unless Dir.exist?(uploads_dir)

      # Generate unique filename
      filename = "#{Time.current.to_i}_#{SecureRandom.hex(8)}#{File.extname(image.original_filename)}"
      file_path = uploads_dir.join(filename)

      # Save file
      File.open(file_path, "wb") do |file|
        file.write(image.read)
      end

      # Return URL - use request host for proper URL in all environments
      url = "#{request.protocol}#{request.host_with_port}/uploads/#{filename}"
      render json: { url: url }, status: :ok
    rescue => e
      Rails.logger.error "Image upload error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n") if Rails.env.development?
      render json: { error: "Failed to upload image: #{e.message}" }, status: :internal_server_error
    end
  end

  def show
    filename = params[:path]
    file_path = Rails.root.join("public", "uploads", filename)

    if File.exist?(file_path)
      send_file file_path, type: "image/#{File.extname(filename)[1..]}", disposition: "inline"
    else
      render json: { error: "File not found" }, status: :not_found
    end
  end
end
