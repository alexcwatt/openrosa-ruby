# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe OpenRosa::MediaFile do
  describe "initialization" do
    it "creates a media file with required attributes" do
      media_file = described_class.new(
        filename: "images/photo.jpg",
        hash: "md5:abc123",
        download_url: "https://example.com/media/photo.jpg"
      )

      expect(media_file.filename).to eq("images/photo.jpg")
      expect(media_file.hash).to eq("md5:abc123")
      expect(media_file.download_url).to eq("https://example.com/media/photo.jpg")
    end

    it "creates a media file with optional type" do
      media_file = described_class.new(
        filename: "data.csv",
        hash: "md5:def456",
        download_url: "https://example.com/data.csv",
        type: "image"
      )

      expect(media_file.type).to eq("image")
    end

    it "creates a media file with integrity_url for entity lists" do
      media_file = described_class.new(
        filename: "entities.csv",
        hash: "md5:xyz789",
        download_url: "https://example.com/entities.csv",
        type: "entityList",
        integrity_url: "https://example.com/entities/integrity"
      )

      expect(media_file.integrity_url).to eq("https://example.com/entities/integrity")
    end
  end

  describe "filename validation" do
    it "accepts valid unix-style paths" do
      expect do
        described_class.new(
          filename: "images/photo.jpg",
          hash: "md5:abc",
          download_url: "http://example.com/photo.jpg"
        )
      end.not_to raise_error
    end

    it "accepts simple filenames" do
      expect do
        described_class.new(
          filename: "photo.jpg",
          hash: "md5:abc",
          download_url: "http://example.com/photo.jpg"
        )
      end.not_to raise_error
    end

    it "rejects filenames with Windows drive letters" do
      expect do
        described_class.new(
          filename: "C:/images/photo.jpg",
          hash: "md5:abc",
          download_url: "http://example.com/photo.jpg"
        )
      end.to raise_error(ArgumentError, /drive letter/)
    end

    it "rejects filenames with relative paths (..)" do
      expect do
        described_class.new(
          filename: "../images/photo.jpg",
          hash: "md5:abc",
          download_url: "http://example.com/photo.jpg"
        )
      end.to raise_error(ArgumentError, /relative path/)
    end

    it "rejects filenames starting with /" do
      expect do
        described_class.new(
          filename: "/images/photo.jpg",
          hash: "md5:abc",
          download_url: "http://example.com/photo.jpg"
        )
      end.to raise_error(ArgumentError, /absolute path/)
    end

    it "rejects filenames with backslashes" do
      expect do
        described_class.new(
          filename: "images\\photo.jpg",
          hash: "md5:abc",
          download_url: "http://example.com/photo.jpg"
        )
      end.to raise_error(ArgumentError, /backslash/)
    end
  end

  describe "hash generation from file" do
    it "generates MD5 hash from file content" do
      # Create a temporary file
      file = Tempfile.new("test_file")
      file.write("Hello, World!")
      file.rewind

      media_file = described_class.new(
        filename: "test.txt",
        file: file.path,
        download_url: "http://example.com/test.txt"
      )

      # MD5 of "Hello, World!" is 65a8e27d8879283831b664bd8b7f0ad4
      expect(media_file.hash).to eq("md5:65a8e27d8879283831b664bd8b7f0ad4")

      file.close
      file.unlink
    end

    it "allows manual hash override" do
      file = Tempfile.new("test_file")
      file.write("Hello, World!")
      file.rewind

      media_file = described_class.new(
        filename: "test.txt",
        file: file.path,
        hash: "md5:custom_hash",
        download_url: "http://example.com/test.txt"
      )

      expect(media_file.hash).to eq("md5:custom_hash")

      file.close
      file.unlink
    end

    it "requires either hash or file parameter" do
      expect do
        described_class.new(
          filename: "test.txt",
          download_url: "http://example.com/test.txt"
        )
      end.to raise_error(ArgumentError, /hash or file/)
    end
  end

  describe "entityList validation" do
    it "requires integrity_url when type is entityList" do
      expect do
        described_class.new(
          filename: "entities.csv",
          hash: "md5:abc",
          download_url: "http://example.com/entities.csv",
          type: "entityList"
        )
      end.to raise_error(ArgumentError, /integrity_url is required/)
    end

    it "allows integrity_url for entityList type" do
      expect do
        described_class.new(
          filename: "entities.csv",
          hash: "md5:abc",
          download_url: "http://example.com/entities.csv",
          type: "entityList",
          integrity_url: "http://example.com/integrity"
        )
      end.not_to raise_error
    end

    it "allows other types without integrity_url" do
      expect do
        described_class.new(
          filename: "image.jpg",
          hash: "md5:abc",
          download_url: "http://example.com/image.jpg",
          type: "image"
        )
      end.not_to raise_error
    end
  end
end
