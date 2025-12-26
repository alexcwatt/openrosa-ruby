# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenRosa::Fields::Upload do
  describe "initialization" do
    it "inherits from Base" do
      field = OpenRosa::Fields::Upload.new(:photo)
      expect(field).to be_a(OpenRosa::Fields::Base)
    end

    it "accepts mediatype option" do
      field = OpenRosa::Fields::Upload.new(:photo, mediatype: "image/*")
      expect(field.mediatype).to eq("image/*")
    end

    it "defaults mediatype to nil" do
      field = OpenRosa::Fields::Upload.new(:file)
      expect(field.mediatype).to be_nil
    end

    it "accepts max_pixels option for images" do
      field = OpenRosa::Fields::Upload.new(:photo, max_pixels: 1024)
      expect(field.max_pixels).to eq(1024)
    end
  end

  describe "media types" do
    it "supports image/* mediatype" do
      field = OpenRosa::Fields::Upload.new(:photo, mediatype: "image/*")
      expect(field.mediatype).to eq("image/*")
    end

    it "supports audio/* mediatype" do
      field = OpenRosa::Fields::Upload.new(:recording, mediatype: "audio/*")
      expect(field.mediatype).to eq("audio/*")
    end

    it "supports video/* mediatype" do
      field = OpenRosa::Fields::Upload.new(:clip, mediatype: "video/*")
      expect(field.mediatype).to eq("video/*")
    end

    it "supports specific MIME types" do
      field = OpenRosa::Fields::Upload.new(:document, mediatype: "application/pdf")
      expect(field.mediatype).to eq("application/pdf")
    end
  end

  describe "full example" do
    let(:field) do
      OpenRosa::Fields::Upload.new(
        :receipt_photo,
        label: "Upload Receipt",
        hint: "Take a clear photo of your receipt",
        mediatype: "image/*",
        required: true,
        max_pixels: 1024
      )
    end

    it "stores all attributes correctly" do
      expect(field.name).to eq(:receipt_photo)
      expect(field.label).to eq("Upload Receipt")
      expect(field.hint).to eq("Take a clear photo of your receipt")
      expect(field.mediatype).to eq("image/*")
      expect(field.required).to eq(true)
      expect(field.max_pixels).to eq(1024)
    end
  end
end
