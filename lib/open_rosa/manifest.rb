# frozen_string_literal: true

require "nokogiri"

module OpenRosa
  # Represents a manifest of media files associated with a form.
  # The manifest lists all supporting files (images, audio, video, entity lists)
  # that need to be downloaded along with the form definition.
  #
  # @example Create a manifest with media files
  #   manifest = OpenRosa::Manifest.new
  #   manifest.add_media_file(
  #     OpenRosa::MediaFile.new(
  #       filename: "images/logo.png",
  #       hash: "md5:abc123",
  #       download_url: "https://example.com/media/logo.png"
  #     )
  #   )
  #   xml = manifest.to_xml
  #
  # @example Create a manifest with entity list
  #   manifest = OpenRosa::Manifest.new
  #   manifest.add_media_file(
  #     OpenRosa::MediaFile.new(
  #       filename: "entities.csv",
  #       hash: "md5:xyz789",
  #       download_url: "https://example.com/entities.csv",
  #       type: "entityList",
  #       integrity_url: "https://example.com/entities/integrity"
  #     )
  #   )
  class Manifest
    attr_reader :media_files

    # Creates a new Manifest
    #
    # @param media_files [Array<MediaFile>] Optional array of MediaFile objects
    def initialize(media_files: [])
      @media_files = media_files
    end

    # Adds a media file to the manifest
    #
    # @param media_file [MediaFile] The media file to add
    # @return [Manifest] self for chaining
    def add_media_file(media_file)
      @media_files << media_file
      self
    end

    # Generates OpenRosa manifest XML
    #
    # @return [String] XML string conforming to OpenRosa manifest spec
    def to_xml
      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml.manifest(xmlns: "http://openrosa.org/xforms/xformsManifest") do
          media_files.each do |media_file|
            build_media_file(xml, media_file)
          end
        end
      end

      builder.to_xml
    end

    # Check if the manifest is empty
    #
    # @return [Boolean] true if no media files
    def empty?
      media_files.empty?
    end

    # Count of media files in the manifest
    #
    # @return [Integer] number of media files
    def count
      media_files.count
    end

    private

    def build_media_file(xml, media_file)
      # Add type attribute only if specified
      if media_file.type
        xml.mediaFile(type: media_file.type) do
          build_media_file_elements(xml, media_file)
        end
      else
        xml.mediaFile do
          build_media_file_elements(xml, media_file)
        end
      end
    end

    def build_media_file_elements(xml, media_file)
      xml.filename media_file.filename
      # Use text approach to avoid conflict with Object#hash
      xml.text("\n    ")
      xml.parent.add_child(Nokogiri::XML::Node.new("hash", xml.doc).tap { |n| n.content = media_file.hash })
      xml.text("\n    ")
      xml.downloadUrl media_file.download_url
      xml.integrityUrl media_file.integrity_url if media_file.integrity_url
    end
  end
end
