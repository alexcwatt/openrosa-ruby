# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenRosa::Manifest do
  describe "initialization" do
    it "creates an empty manifest" do
      manifest = described_class.new

      expect(manifest.media_files).to be_empty
    end

    it "creates a manifest with media files" do
      media_file = OpenRosa::MediaFile.new(
        filename: "photo.jpg",
        hash: "md5:abc123",
        download_url: "https://example.com/photo.jpg"
      )

      manifest = described_class.new(media_files: [media_file])

      expect(manifest.media_files).to eq([media_file])
    end
  end

  describe "#add_media_file" do
    it "adds a media file to the manifest" do
      manifest = described_class.new
      media_file = OpenRosa::MediaFile.new(
        filename: "photo.jpg",
        hash: "md5:abc123",
        download_url: "https://example.com/photo.jpg"
      )

      manifest.add_media_file(media_file)

      expect(manifest.media_files).to include(media_file)
    end

    it "supports chaining" do
      manifest = described_class.new
      file1 = OpenRosa::MediaFile.new(
        filename: "photo1.jpg",
        hash: "md5:abc",
        download_url: "https://example.com/photo1.jpg"
      )
      file2 = OpenRosa::MediaFile.new(
        filename: "photo2.jpg",
        hash: "md5:def",
        download_url: "https://example.com/photo2.jpg"
      )

      manifest.add_media_file(file1).add_media_file(file2)

      expect(manifest.media_files).to eq([file1, file2])
    end
  end

  describe "#to_xml" do
    it "generates empty manifest XML" do
      manifest = described_class.new

      xml = manifest.to_xml

      expect(xml).to include('<?xml version="1.0"')
      expect(xml).to include('<manifest xmlns="http://openrosa.org/xforms/xformsManifest"')
    end

    it "generates manifest XML with a single media file" do
      media_file = OpenRosa::MediaFile.new(
        filename: "images/photo.jpg",
        hash: "md5:abc123",
        download_url: "https://example.com/media/photo.jpg"
      )
      manifest = described_class.new(media_files: [media_file])

      xml = manifest.to_xml

      expect(xml).to include("<mediaFile>")
      expect(xml).to include("<filename>images/photo.jpg</filename>")
      expect(xml).to include("<hash>md5:abc123</hash>")
      expect(xml).to include("<downloadUrl>https://example.com/media/photo.jpg</downloadUrl>")
      expect(xml).to include("</mediaFile>")
    end

    it "generates manifest XML with multiple media files" do
      file1 = OpenRosa::MediaFile.new(
        filename: "images/photo1.jpg",
        hash: "md5:abc",
        download_url: "https://example.com/photo1.jpg"
      )
      file2 = OpenRosa::MediaFile.new(
        filename: "audio/sound.mp3",
        hash: "md5:def",
        download_url: "https://example.com/sound.mp3"
      )
      manifest = described_class.new(media_files: [file1, file2])

      xml = manifest.to_xml

      expect(xml).to include("<filename>images/photo1.jpg</filename>")
      expect(xml).to include("<filename>audio/sound.mp3</filename>")
    end

    it "includes type attribute for entity lists" do
      media_file = OpenRosa::MediaFile.new(
        filename: "entities.csv",
        hash: "md5:xyz789",
        download_url: "https://example.com/entities.csv",
        type: "entityList",
        integrity_url: "https://example.com/entities/integrity"
      )
      manifest = described_class.new(media_files: [media_file])

      xml = manifest.to_xml

      expect(xml).to include("<mediaFile type=\"entityList\">")
      expect(xml).to include("<filename>entities.csv</filename>")
      expect(xml).to include("<hash>md5:xyz789</hash>")
      expect(xml).to include("<downloadUrl>https://example.com/entities.csv</downloadUrl>")
      expect(xml).to include("<integrityUrl>https://example.com/entities/integrity</integrityUrl>")
    end

    it "omits type attribute for regular media files" do
      media_file = OpenRosa::MediaFile.new(
        filename: "photo.jpg",
        hash: "md5:abc",
        download_url: "https://example.com/photo.jpg"
      )
      manifest = described_class.new(media_files: [media_file])

      xml = manifest.to_xml

      expect(xml).to include("<mediaFile>")
      expect(xml).not_to include("type=")
    end

    it "generates valid XML that can be parsed" do
      media_file = OpenRosa::MediaFile.new(
        filename: "photo.jpg",
        hash: "md5:abc123",
        download_url: "https://example.com/photo.jpg"
      )
      manifest = described_class.new(media_files: [media_file])

      xml = manifest.to_xml
      doc = Nokogiri::XML(xml)

      expect(doc.errors).to be_empty
      expect(doc.at_xpath("//xmlns:manifest", "xmlns" => "http://openrosa.org/xforms/xformsManifest")).not_to be_nil
    end
  end

  describe "#empty?" do
    it "returns true for empty manifest" do
      manifest = described_class.new

      expect(manifest.empty?).to be true
    end

    it "returns false for manifest with media files" do
      media_file = OpenRosa::MediaFile.new(
        filename: "photo.jpg",
        hash: "md5:abc",
        download_url: "https://example.com/photo.jpg"
      )
      manifest = described_class.new(media_files: [media_file])

      expect(manifest.empty?).to be false
    end
  end

  describe "#count" do
    it "returns 0 for empty manifest" do
      manifest = described_class.new

      expect(manifest.count).to eq(0)
    end

    it "returns count of media files" do
      file1 = OpenRosa::MediaFile.new(
        filename: "photo1.jpg",
        hash: "md5:abc",
        download_url: "https://example.com/photo1.jpg"
      )
      file2 = OpenRosa::MediaFile.new(
        filename: "photo2.jpg",
        hash: "md5:def",
        download_url: "https://example.com/photo2.jpg"
      )
      manifest = described_class.new(media_files: [file1, file2])

      expect(manifest.count).to eq(2)
    end
  end
end
