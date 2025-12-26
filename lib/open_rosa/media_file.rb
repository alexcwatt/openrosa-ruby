# frozen_string_literal: true

require "digest"

module OpenRosa
  # Represents a media file (image, audio, video, entity list) associated with a form.
  # Media files are listed in the form's manifest and downloaded separately from the form definition.
  #
  # @example Create a media file with manual hash
  #   media_file = OpenRosa::MediaFile.new(
  #     filename: "images/logo.png",
  #     hash: "md5:abc123def456",
  #     download_url: "https://example.com/media/logo.png"
  #   )
  #
  # @example Create a media file with automatic hash generation
  #   media_file = OpenRosa::MediaFile.new(
  #     filename: "images/logo.png",
  #     file: "/path/to/logo.png",
  #     download_url: "https://example.com/media/logo.png"
  #   )
  #
  # @example Create an entity list media file
  #   media_file = OpenRosa::MediaFile.new(
  #     filename: "entities.csv",
  #     hash: "md5:xyz789",
  #     download_url: "https://example.com/entities.csv",
  #     type: "entityList",
  #     integrity_url: "https://example.com/entities/integrity"
  #   )
  class MediaFile
    attr_reader :filename, :hash, :download_url, :type, :integrity_url

    # Creates a new MediaFile
    #
    # @param filename [String] Unrooted file path (no drive letters, no absolute paths, no backslashes)
    # @param hash [String, nil] MD5 hash in format "md5:..." (auto-generated if file provided)
    # @param file [String, nil] Path to file for hash generation
    # @param download_url [String] Full URI for downloading the file
    # @param type [String, nil] Optional type (e.g., "entityList")
    # @param integrity_url [String, nil] Required if type="entityList"
    # @raise [ArgumentError] if filename is invalid, or if hash/file not provided, or entityList missing integrity_url
    # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
    def initialize(filename:, download_url:, hash: nil, file: nil, type: nil, integrity_url: nil)
      # rubocop:enable Metrics/ParameterLists
      @filename = validate_filename(filename)
      @download_url = download_url
      @type = type
      @integrity_url = integrity_url

      # Hash can be provided or generated from file
      if hash
        @hash = hash
      elsif file
        @hash = generate_hash(file)
      else
        raise ArgumentError, "Either hash or file parameter must be provided"
      end

      # Validate entityList requirements
      validate_entity_list if type == "entityList"
    end
    # rubocop:enable Metrics/MethodLength

    private

    def validate_filename(filename)
      # Check for Windows drive letters (C:, D:, etc.)
      raise ArgumentError, "Filename cannot contain a drive letter: #{filename}" if filename.match?(/^[A-Za-z]:/)

      # Check for relative paths (..)
      if filename.include?("..")
        raise ArgumentError, "Filename cannot contain relative path components (..): #{filename}"
      end

      # Check for absolute paths (starting with /)
      raise ArgumentError, "Filename cannot be an absolute path: #{filename}" if filename.start_with?("/")

      # Check for backslashes (Windows-style paths)
      raise ArgumentError, "Filename cannot contain backslash characters: #{filename}" if filename.include?("\\")

      filename
    end

    def generate_hash(file_path)
      content = File.read(file_path)
      digest = Digest::MD5.hexdigest(content)
      "md5:#{digest}"
    end

    def validate_entity_list
      return if integrity_url

      raise ArgumentError, "integrity_url is required when type is 'entityList'"
    end
  end
end
