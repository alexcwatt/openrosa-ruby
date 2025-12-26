# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenRosa::FormList do
  let(:form1) do
    Class.new(OpenRosa::Form) do
      form_id "survey_001"
      version "1.0"
      name "Customer Survey"
      download_url "https://example.com/forms/survey_001"

      input :name, label: "Name", type: :string
    end
  end

  let(:form2) do
    Class.new(OpenRosa::Form) do
      form_id "feedback_002"
      version "2.0"
      name "Feedback Form"
      description_text "Please provide your feedback"
      description_url "https://example.com/forms/feedback_002/info"
      download_url "https://example.com/forms/feedback_002"
      manifest_url "https://example.com/manifests/feedback_002"

      input :rating, label: "Rating", type: :int
    end
  end

  describe "basic XML generation" do
    let(:form_list) { OpenRosa::FormList.new([form1]) }

    it "generates valid XML structure" do
      xml = form_list.to_xml
      expect(xml).to include('<?xml version="1.0" encoding="UTF-8"?>')
      expect(xml).to include('<xforms xmlns="http://openrosa.org/xforms/xformsList">')
      expect(xml).to include("</xforms>")
    end

    it "includes form metadata" do
      xml = form_list.to_xml
      expect(xml).to include("<formID>survey_001</formID>")
      expect(xml).to include("<name>Customer Survey</name>")
      expect(xml).to include("<version>1.0</version>")
      expect(xml).to include("<hash>md5:")
      expect(xml).to include("<downloadUrl>https://example.com/forms/survey_001</downloadUrl>")
    end
  end

  describe "multiple forms" do
    let(:form_list) { OpenRosa::FormList.new([form1, form2]) }

    it "includes all forms" do
      xml = form_list.to_xml
      expect(xml).to include("<formID>survey_001</formID>")
      expect(xml).to include("<formID>feedback_002</formID>")
    end

    it "includes each form's metadata" do
      xml = form_list.to_xml
      expect(xml).to include("<name>Customer Survey</name>")
      expect(xml).to include("<name>Feedback Form</name>")
      expect(xml).to include("<version>1.0</version>")
      expect(xml).to include("<version>2.0</version>")
    end
  end

  describe "verbose mode" do
    let(:form_list) { OpenRosa::FormList.new([form2], verbose: true) }

    it "includes description fields" do
      xml = form_list.to_xml
      expect(xml).to include("<descriptionText>Please provide your feedback</descriptionText>")
      expect(xml).to include("<descriptionUrl>https://example.com/forms/feedback_002/info</descriptionUrl>")
    end
  end

  describe "non-verbose mode" do
    let(:form_list) { OpenRosa::FormList.new([form2], verbose: false) }

    it "does not include description fields" do
      xml = form_list.to_xml
      expect(xml).not_to include("descriptionText")
      expect(xml).not_to include("descriptionUrl")
    end
  end

  describe "manifest URL" do
    let(:form_list) { OpenRosa::FormList.new([form2]) }

    it "includes manifestUrl when present" do
      xml = form_list.to_xml
      expect(xml).to include("<manifestUrl>https://example.com/manifests/feedback_002</manifestUrl>")
    end
  end

  describe "filtering by formID" do
    let(:form_list) { OpenRosa::FormList.new([form1, form2], form_id: "survey_001") }

    it "only includes matching form" do
      xml = form_list.to_xml
      expect(xml).to include("<formID>survey_001</formID>")
      expect(xml).not_to include("<formID>feedback_002</formID>")
    end
  end

  describe "empty form list" do
    let(:form_list) { OpenRosa::FormList.new([]) }

    it "generates valid XML with no forms" do
      xml = form_list.to_xml
      expect(xml).to include('xmlns="http://openrosa.org/xforms/xformsList"')
      expect(xml).not_to include("<xform>")
    end
  end

  describe "auto-generated download_url" do
    let(:form_without_download_url) do
      Class.new(OpenRosa::Form) do
        form_id "no_url_form"
        version "1.0"
        name "Form Without URL"

        input :name, label: "Name", type: :string
      end
    end

    context "when form has no download_url and no base_url configured" do
      let(:form_list) { OpenRosa::FormList.new([form_without_download_url]) }

      it "raises an error" do
        expect { form_list.to_xml }.to raise_error(
          ArgumentError,
          /Form 'no_url_form' has no download_url/
        )
      end
    end

    context "when base_url is provided" do
      let(:form_list) { OpenRosa::FormList.new([form_without_download_url], base_url: "https://myserver.com") }

      it "auto-generates downloadUrl using default mount_path" do
        xml = form_list.to_xml
        expect(xml).to include("<downloadUrl>https://myserver.com/openrosa/forms/no_url_form</downloadUrl>")
      end
    end

    context "when base_url and custom mount_path are provided" do
      let(:form_list) do
        OpenRosa::FormList.new([form_without_download_url], base_url: "https://api.example.org", mount_path: "/api/v2")
      end

      it "auto-generates downloadUrl using custom mount_path" do
        xml = form_list.to_xml
        expect(xml).to include("<downloadUrl>https://api.example.org/api/v2/forms/no_url_form</downloadUrl>")
      end
    end

    context "when form has explicit download_url" do
      it "uses the explicit download_url even if base_url is provided" do
        form_list = OpenRosa::FormList.new([form1], base_url: "https://different.com")
        xml = form_list.to_xml
        expect(xml).to include("<downloadUrl>https://example.com/forms/survey_001</downloadUrl>")
        expect(xml).not_to include("different.com")
      end
    end
  end

  describe "auto-generated manifest_url" do
    let(:form_with_manifest) do
      Class.new(OpenRosa::Form) do
        form_id "media_form"
        version "1.0"
        name "Form With Media"
        download_url "https://example.com/forms/media_form"

        input :name, label: "Name", type: :string

        def self.manifest
          @manifest ||= OpenRosa::Manifest.new(
            media_files: [
              OpenRosa::MediaFile.new(
                filename: "image.png",
                hash: "md5:abc123",
                download_url: "https://example.com/media/image.png"
              )
            ]
          )
        end
      end
    end

    context "when form has manifest but no manifest_url and no base_url" do
      let(:form_list) { OpenRosa::FormList.new([form_with_manifest]) }

      it "does not include manifestUrl" do
        xml = form_list.to_xml
        expect(xml).not_to include("manifestUrl")
      end
    end

    context "when form has manifest and base_url is provided" do
      let(:form_list) { OpenRosa::FormList.new([form_with_manifest], base_url: "https://myserver.com") }

      it "auto-generates manifestUrl using default mount_path" do
        xml = form_list.to_xml
        expect(xml).to include("<manifestUrl>https://myserver.com/openrosa/manifests/media_form</manifestUrl>")
      end
    end

    context "when form has manifest and custom mount_path is provided" do
      let(:form_list) do
        OpenRosa::FormList.new([form_with_manifest], base_url: "https://api.example.org", mount_path: "/api/v2")
      end

      it "auto-generates manifestUrl using custom mount_path" do
        xml = form_list.to_xml
        expect(xml).to include("<manifestUrl>https://api.example.org/api/v2/manifests/media_form</manifestUrl>")
      end
    end

    context "when form has no manifest" do
      let(:form_list) { OpenRosa::FormList.new([form1], base_url: "https://myserver.com") }

      it "does not include manifestUrl" do
        xml = form_list.to_xml
        expect(xml).not_to include("manifestUrl")
      end
    end

    context "when form has explicit manifest_url" do
      it "uses the explicit manifest_url even if base_url is provided" do
        form_list = OpenRosa::FormList.new([form2], base_url: "https://different.com")
        xml = form_list.to_xml
        expect(xml).to include("<manifestUrl>https://example.com/manifests/feedback_002</manifestUrl>")
        expect(xml).not_to include("different.com/openrosa/manifests")
      end
    end
  end
end
