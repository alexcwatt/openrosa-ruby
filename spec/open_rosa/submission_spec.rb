# frozen_string_literal: true

require "spec_helper"
require "rack/test"
require "tempfile"

RSpec.describe OpenRosa::Submission do
  include Rack::Test::Methods

  describe ".parse" do
    let(:form_id) { "test_form" }
    let(:instance_id) { "uuid:12345678-1234-1234-1234-123456789012" }

    let(:xml_content) do
      <<~XML
        <?xml version="1.0"?>
        <test_form id="test_form">
          <name>John Doe</name>
          <age>30</age>
          <meta>
            <instanceID>#{instance_id}</instanceID>
            <timeStart>2024-01-01T10:00:00.000Z</timeStart>
            <timeEnd>2024-01-01T10:05:00.000Z</timeEnd>
            <deviceID>device123</deviceID>
          </meta>
        </test_form>
      XML
    end

    context "with valid multipart submission" do
      it "parses XML submission file" do
        request = build_request(xml_content)
        submission = described_class.parse(request)

        expect(submission.form_id).to eq("test_form")
        expect(submission.instance_id).to eq(instance_id)
        expect(submission.data).to include("name" => "John Doe", "age" => "30")
        expect(submission.metadata).to include(
          instanceID: instance_id,
          timeStart: "2024-01-01T10:00:00.000Z",
          timeEnd: "2024-01-01T10:05:00.000Z",
          deviceID: "device123"
        )
      end

      it "stores raw XML" do
        request = build_request(xml_content)
        submission = described_class.parse(request)

        expect(submission.raw_xml).to include("<test_form")
        expect(submission.raw_xml).to include("<name>John Doe</name>")
      end
    end

    context "with file attachments" do
      it "extracts uploaded files" do
        image_file = Tempfile.new(["test", ".jpg"])
        image_file.write("fake image data")
        image_file.rewind

        request = build_request(xml_content, attachments: { "photo" => image_file })
        submission = described_class.parse(request)

        expect(submission.attachments.size).to eq(1)
        attachment = submission.attachments.first
        expect(attachment.filename).to match(/test.*\.jpg/)
        expect(attachment.content_type).to eq("image/jpeg")
        expect(attachment.read).to eq("fake image data")
      ensure
        image_file.close
        image_file.unlink
      end
    end

    context "with nested groups in XML" do
      let(:xml_with_groups) do
        <<~XML
          <?xml version="1.0"?>
          <survey id="survey">
            <personal>
              <name>Jane</name>
              <email>jane@example.com</email>
            </personal>
            <meta>
              <instanceID>uuid:abc123</instanceID>
            </meta>
          </survey>
        XML
      end

      it "flattens nested field names with path separator" do
        request = build_request(xml_with_groups)
        submission = described_class.parse(request)

        expect(submission.data).to include(
          "personal/name" => "Jane",
          "personal/email" => "jane@example.com"
        )
      end
    end

    context "with invalid requests" do
      it "raises error for non-POST requests" do
        env = Rack::MockRequest.env_for("/submission", method: "GET")
        request = Rack::Request.new(env)

        expect { described_class.parse(request) }.to raise_error(
          OpenRosa::Submission::ParseError,
          "Request must be POST"
        )
      end

      it "raises error for non-multipart content type" do
        env = Rack::MockRequest.env_for(
          "/submission",
          method: "POST",
          "CONTENT_TYPE" => "application/json",
          input: "{}"
        )
        request = Rack::Request.new(env)

        expect { described_class.parse(request) }.to raise_error(
          OpenRosa::Submission::ParseError,
          "Content-Type must be multipart/form-data"
        )
      end

      it "raises error when xml_submission_file is missing" do
        # Create a multipart request without xml_submission_file (but with other param to trigger multipart)
        captured_request = nil
        app = lambda do |env|
          captured_request = Rack::Request.new(env)
          [200, {}, []]
        end

        session = Rack::Test::Session.new(app)
        session.post("/submission", {
                       "other_file" => Rack::Test::UploadedFile.new(
                         StringIO.new("test"),
                         "text/plain",
                         original_filename: "test.txt"
                       )
                     })

        expect { described_class.parse(captured_request) }.to raise_error(
          OpenRosa::Submission::ParseError,
          "Missing xml_submission_file parameter"
        )
      end

      it "raises error for invalid XML" do
        request = build_request("<invalid><xml>")

        expect { described_class.parse(request) }.to raise_error(
          OpenRosa::Submission::ParseError,
          /Invalid XML/
        )
      end
    end

    context "when form ID comes from element name" do
      let(:xml_without_id) do
        <<~XML
          <?xml version="1.0"?>
          <my_survey>
            <answer>Yes</answer>
            <meta>
              <instanceID>uuid:xyz</instanceID>
            </meta>
          </my_survey>
        XML
      end

      it "uses root element name as form_id" do
        request = build_request(xml_without_id)
        submission = described_class.parse(request)

        expect(submission.form_id).to eq("my_survey")
      end
    end

    context "when instance ID is missing" do
      let(:xml_without_instance_id) do
        <<~XML
          <?xml version="1.0"?>
          <form id="form1">
            <field>value</field>
          </form>
        XML
      end

      it "allows nil instance_id" do
        request = build_request(xml_without_instance_id)
        submission = described_class.parse(request)

        expect(submission.instance_id).to be_nil
      end
    end
  end

  describe OpenRosa::Submission::Attachment do
    let(:tempfile) do
      file = Tempfile.new("test")
      file.write("test content")
      file.rewind
      file
    end

    let(:attachment) do
      described_class.new(
        filename: "test.txt",
        content_type: "text/plain",
        size: 12,
        tempfile: tempfile
      )
    end

    after do
      tempfile.close
      tempfile.unlink
    end

    it "provides access to file attributes" do
      expect(attachment.filename).to eq("test.txt")
      expect(attachment.content_type).to eq("text/plain")
      expect(attachment.size).to eq(12)
    end

    it "can read file contents" do
      expect(attachment.read).to eq("test content")
    end

    it "can get file path" do
      expect(attachment.path).to eq(tempfile.path)
    end

    it "rewinds before reading" do
      attachment.read # First read
      expect(attachment.read).to eq("test content") # Should still work
    end
  end

  # rubocop:disable Metrics/MethodLength
  def build_request(xml_content, attachments: {})
    # Create a minimal Rack app to capture the request
    captured_request = nil
    app = lambda do |env|
      captured_request = Rack::Request.new(env)
      [200, {}, []]
    end

    session = Rack::Test::Session.new(app)

    params = {
      "xml_submission_file" => Rack::Test::UploadedFile.new(
        StringIO.new(xml_content),
        "text/xml",
        original_filename: "submission.xml"
      )
    }

    attachments.each do |name, tempfile|
      params[name.to_s] = Rack::Test::UploadedFile.new(
        tempfile,
        "image/jpeg"
      )
    end

    session.post("/submission", params)
    captured_request
  end
  # rubocop:enable Metrics/MethodLength
end
