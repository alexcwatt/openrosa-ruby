# frozen_string_literal: true

require "spec_helper"
require "rack/test"
require "securerandom"

RSpec.describe OpenRosa::Middleware do
  include Rack::Test::Methods

  # Create sample forms for testing
  let(:sample_form_class) do
    Class.new(OpenRosa::Form) do
      form_id "survey_001"
      version "1.0.0"
      name "Test Survey"
      download_url "https://example.com/forms/survey_001"

      input :name, label: "Your Name", type: :string
      input :age, label: "Your Age", type: :int
    end
  end

  let(:another_form_class) do
    Class.new(OpenRosa::Form) do
      form_id "survey_002"
      version "2.0.0"
      name "Another Survey"
      download_url "https://example.com/forms/survey_002"

      input :email, label: "Email", type: :string
    end
  end

  describe "Configuration" do
    it "has default mount path" do
      config = OpenRosa::Middleware::Configuration.new
      expect(config.mount_path).to eq("/openrosa")
    end

    it "has empty forms by default" do
      config = OpenRosa::Middleware::Configuration.new
      expect(config.forms).to eq([])
    end

    it "allows setting forms" do
      config = OpenRosa::Middleware::Configuration.new
      config.forms = [sample_form_class]
      expect(config.forms).to eq([sample_form_class])
    end

    it "allows setting mount_path" do
      config = OpenRosa::Middleware::Configuration.new
      config.mount_path = "/custom"
      expect(config.mount_path).to eq("/custom")
    end

    it "has nil base_url by default" do
      config = OpenRosa::Middleware::Configuration.new
      expect(config.base_url).to be_nil
    end

    it "allows setting base_url" do
      config = OpenRosa::Middleware::Configuration.new
      config.base_url = "https://example.com"
      expect(config.base_url).to eq("https://example.com")
    end
  end

  describe "Middleware initialization" do
    it "can be initialized without an app" do
      middleware = OpenRosa::Middleware.new
      expect(middleware.app).to be_nil
    end

    it "can be initialized with an app" do
      app = ->(_env) { [200, {}, ["Hello"]] }
      middleware = OpenRosa::Middleware.new(app)
      expect(middleware.app).to eq(app)
    end

    it "accepts configuration block" do
      middleware = OpenRosa::Middleware.new do |config|
        config.forms = [sample_form_class]
        config.mount_path = "/custom"
      end

      expect(middleware.config.forms).to eq([sample_form_class])
      expect(middleware.config.mount_path).to eq("/custom")
    end
  end

  describe "GET /openrosa/formList" do
    let(:app) do
      OpenRosa::Middleware.new do |config|
        config.forms = [sample_form_class, another_form_class]
      end
    end

    it "returns list of all forms" do
      get "/openrosa/formList"

      expect(last_response.status).to eq(200)
      expect(last_response.headers["Content-Type"]).to eq("text/xml; charset=utf-8")
      expect(last_response.headers["X-OpenRosa-Version"]).to eq("1.0")
      expect(last_response.headers["Date"]).not_to be_nil

      xml = last_response.body
      expect(xml).to include("<xforms")
      expect(xml).to include("<formID>survey_001</formID>")
      expect(xml).to include("<formID>survey_002</formID>")
      expect(xml).to include("<name>Test Survey</name>")
      expect(xml).to include("<name>Another Survey</name>")
    end

    it "filters forms by formID parameter" do
      get "/openrosa/formList?formID=survey_001"

      expect(last_response.status).to eq(200)
      xml = last_response.body
      expect(xml).to include("<formID>survey_001</formID>")
      expect(xml).not_to include("<formID>survey_002</formID>")
    end

    it "supports verbose mode" do
      get "/openrosa/formList?verbose=true"

      expect(last_response.status).to eq(200)
      xml = last_response.body
      expect(xml).to include("<xforms")
    end

    it "returns empty list when no forms match filter" do
      get "/openrosa/formList?formID=nonexistent"

      expect(last_response.status).to eq(200)
      xml = last_response.body
      expect(xml).to include("<xforms")
      expect(xml).not_to include("<xform>")
    end
  end

  describe "GET /openrosa/forms/:id" do
    let(:app) do
      OpenRosa::Middleware.new do |config|
        config.forms = [sample_form_class]
      end
    end

    it "returns XForm XML for valid form" do
      get "/openrosa/forms/survey_001"

      expect(last_response.status).to eq(200)
      expect(last_response.headers["Content-Type"]).to eq("text/xml; charset=utf-8")
      expect(last_response.headers["X-OpenRosa-Version"]).to eq("1.0")

      xml = last_response.body
      expect(xml).to include("<html")
      expect(xml).to include('id="survey_001"')
      expect(xml).to include("<input")
    end

    it "returns 404 for nonexistent form" do
      get "/openrosa/forms/nonexistent"

      expect(last_response.status).to eq(404)
      expect(last_response.body).to eq("Not Found")
    end
  end

  describe "base_url configuration" do
    let(:form_without_url) do
      Class.new(OpenRosa::Form) do
        form_id "no_url_form"
        version "1.0.0"
        name "Form Without URL"

        input :name, label: "Name", type: :string
      end
    end

    let(:app) do
      OpenRosa::Middleware.new do |config|
        config.forms = [form_without_url]
        config.base_url = "https://myserver.com"
      end
    end

    it "auto-generates download_url in formList" do
      get "/openrosa/formList"

      expect(last_response.status).to eq(200)
      xml = last_response.body
      expect(xml).to include("<downloadUrl>https://myserver.com/openrosa/forms/no_url_form</downloadUrl>")
    end

    it "works with custom mount_path" do
      middleware = OpenRosa::Middleware.new do |config|
        config.forms = [form_without_url]
        config.base_url = "https://api.example.org"
        config.mount_path = "/api/v2"
      end

      env = Rack::MockRequest.env_for("/api/v2/formList")
      status, _, body = middleware.call(env)

      expect(status).to eq(200)
      xml = body.join
      expect(xml).to include("<downloadUrl>https://api.example.org/api/v2/forms/no_url_form</downloadUrl>")
    end

    it "prefers explicit download_url over auto-generated" do
      middleware = OpenRosa::Middleware.new do |config|
        config.forms = [sample_form_class]
        config.base_url = "https://different.com"
      end

      env = Rack::MockRequest.env_for("/openrosa/formList")
      status, _, body = middleware.call(env)

      expect(status).to eq(200)
      xml = body.join
      expect(xml).to include("<downloadUrl>https://example.com/forms/survey_001</downloadUrl>")
      expect(xml).not_to include("different.com")
    end

    context "manifest_url auto-generation" do
      let(:form_with_manifest) do
        Class.new(OpenRosa::Form) do
          form_id "media_form"
          version "1.0.0"
          name "Form With Media"

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

      it "auto-generates manifest_url when form has manifest and base_url is set" do
        middleware = OpenRosa::Middleware.new do |config|
          config.forms = [form_with_manifest]
          config.base_url = "https://myserver.com"
        end

        env = Rack::MockRequest.env_for("/openrosa/formList")
        status, _, body = middleware.call(env)

        expect(status).to eq(200)
        xml = body.join
        expect(xml).to include("<manifestUrl>https://myserver.com/openrosa/manifests/media_form</manifestUrl>")
      end

      it "does not include manifest_url for forms without manifest" do
        middleware = OpenRosa::Middleware.new do |config|
          config.forms = [form_without_url]
          config.base_url = "https://myserver.com"
        end

        env = Rack::MockRequest.env_for("/openrosa/formList")
        status, _, body = middleware.call(env)

        expect(status).to eq(200)
        xml = body.join
        expect(xml).not_to include("manifestUrl")
      end
    end
  end

  describe "Custom mount path" do
    let(:app) do
      OpenRosa::Middleware.new do |config|
        config.forms = [sample_form_class]
        config.mount_path = "/custom"
      end
    end

    it "responds to formList at custom path" do
      get "/custom/formList"

      expect(last_response.status).to eq(200)
      expect(last_response.headers["Content-Type"]).to eq("text/xml; charset=utf-8")
    end

    it "responds to forms at custom path" do
      get "/custom/forms/survey_001"

      expect(last_response.status).to eq(200)
      expect(last_response.headers["Content-Type"]).to eq("text/xml; charset=utf-8")
    end

    it "returns 404 for old path" do
      get "/openrosa/formList"

      expect(last_response.status).to eq(404)
    end
  end

  describe "Chaining with other middleware" do
    let(:downstream_app) do
      ->(_env) { [200, { "Content-Type" => "text/plain" }, ["Hello from downstream"]] }
    end

    let(:app) do
      OpenRosa::Middleware.new(downstream_app) do |config|
        config.forms = [sample_form_class]
      end
    end

    it "passes non-OpenRosa requests to downstream app" do
      get "/other/path"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("Hello from downstream")
    end

    it "handles OpenRosa requests without passing to downstream" do
      get "/openrosa/formList"

      expect(last_response.status).to eq(200)
      expect(last_response.headers["X-OpenRosa-Version"]).to eq("1.0")
    end
  end

  describe "Standalone usage (no downstream app)" do
    let(:app) do
      OpenRosa::Middleware.new do |config|
        config.forms = [sample_form_class]
      end
    end

    it "handles OpenRosa requests" do
      get "/openrosa/formList"

      expect(last_response.status).to eq(200)
    end

    it "returns 404 for non-OpenRosa paths" do
      get "/other/path"

      expect(last_response.status).to eq(404)
    end
  end

  describe "Form instances vs classes" do
    let(:form_instance) { sample_form_class.new }

    let(:app) do
      OpenRosa::Middleware.new do |config|
        config.forms = [form_instance]
      end
    end

    it "handles form instances" do
      get "/openrosa/formList"

      expect(last_response.status).to eq(200)
      xml = last_response.body
      expect(xml).to include("<formID>survey_001</formID>")
    end

    it "handles form classes" do
      middleware = OpenRosa::Middleware.new do |config|
        config.forms = [sample_form_class]
      end

      get "/openrosa/formList", {}, "rack.hijack?" => false
      app.call(Rack::MockRequest.env_for("/openrosa/formList"))

      # Create a proper request through the middleware
      env = Rack::MockRequest.env_for("/openrosa/formList")
      status, _, body = middleware.call(env)

      expect(status).to eq(200)
      xml = body.join
      expect(xml).to include("<formID>survey_001</formID>")
    end
  end

  describe "HEAD /openrosa/submission" do
    let(:app) do
      OpenRosa::Middleware.new do |config|
        config.forms = [sample_form_class]
      end
    end

    it "returns 204 with OpenRosa headers" do
      head "/openrosa/submission"

      expect(last_response.status).to eq(204)
      expect(last_response.headers["X-OpenRosa-Version"]).to eq("1.0")
      expect(last_response.headers["X-OpenRosa-Accept-Content-Length"]).to eq("10485760")
      expect(last_response.headers["Date"]).not_to be_nil
      expect(last_response.body).to be_empty
    end

    it "respects custom max_submission_size" do
      middleware = OpenRosa::Middleware.new do |config|
        config.forms = [sample_form_class]
        config.max_submission_size = 5_000_000
      end

      env = Rack::MockRequest.env_for("/openrosa/submission", method: "HEAD")
      status, headers, _body = middleware.call(env)

      expect(status).to eq(204)
      expect(headers["X-OpenRosa-Accept-Content-Length"]).to eq("5000000")
    end
  end

  describe "POST /openrosa/submission" do
    let(:submission_xml) do
      <<~XML
        <?xml version="1.0"?>
        <survey_001 id="survey_001">
          <name>John Doe</name>
          <age>30</age>
          <meta>
            <instanceID>uuid:12345678-1234-1234-1234-123456789012</instanceID>
            <timeStart>2024-01-01T10:00:00.000Z</timeStart>
            <timeEnd>2024-01-01T10:05:00.000Z</timeEnd>
          </meta>
        </survey_001>
      XML
    end

    context "with global submission handler" do
      let(:received_submissions) { [] }

      let(:app) do
        submissions = received_submissions
        OpenRosa::Middleware.new do |config|
          config.forms = [sample_form_class]

          config.on_submission do |submission|
            submissions << submission
            "Thank you for your submission!"
          end
        end
      end

      it "calls the submission handler" do
        post "/openrosa/submission", build_multipart_params(submission_xml)

        expect(last_response.status).to eq(201)
        expect(received_submissions.size).to eq(1)

        submission = received_submissions.first
        expect(submission.form_id).to eq("survey_001")
        expect(submission.data).to include("name" => "John Doe", "age" => "30")
      end

      it "returns OpenRosaResponse XML with custom message" do
        post "/openrosa/submission", build_multipart_params(submission_xml)

        expect(last_response.status).to eq(201)
        expect(last_response.headers["Content-Type"]).to eq("text/xml; charset=utf-8")
        expect(last_response.headers["X-OpenRosa-Version"]).to eq("1.0")

        xml = last_response.body
        expect(xml).to include("<OpenRosaResponse")
        expect(xml).to include("<message>Thank you for your submission!</message>")
      end
    end

    context "with form-specific submission handler" do
      let(:received_data) { [] }

      let(:form_with_handler) do
        data = received_data
        Class.new(OpenRosa::Form) do
          form_id "survey_001"
          version "1.0.0"
          name "Test Survey"

          input :name, label: "Name", type: :string
          input :age, label: "Age", type: :int

          on_submit do |submission|
            data << submission.data
            "Form-specific handler called!"
          end
        end
      end

      let(:app) do
        OpenRosa::Middleware.new do |config|
          config.forms = [form_with_handler]
        end
      end

      it "calls form-specific handler" do
        post "/openrosa/submission", build_multipart_params(submission_xml)

        expect(last_response.status).to eq(201)
        expect(received_data.size).to eq(1)
        expect(received_data.first).to include("name" => "John Doe")

        xml = last_response.body
        expect(xml).to include("<message>Form-specific handler called!</message>")
      end
    end

    context "without submission handler" do
      let(:app) do
        OpenRosa::Middleware.new do |config|
          config.forms = [sample_form_class]
        end
      end

      it "returns default success message" do
        post "/openrosa/submission", build_multipart_params(submission_xml)

        expect(last_response.status).to eq(201)
        xml = last_response.body
        expect(xml).to include("<message>Submission received successfully</message>")
      end
    end

    context "with invalid submission" do
      let(:app) do
        OpenRosa::Middleware.new do |config|
          config.forms = [sample_form_class]
        end
      end

      it "returns 400 for missing xml_submission_file" do
        post "/openrosa/submission", {}

        expect(last_response.status).to eq(400)
        expect(last_response.body).to include("Invalid submission")
      end

      it "returns 400 for invalid XML" do
        post "/openrosa/submission", build_multipart_params("<invalid><xml>")

        expect(last_response.status).to eq(400)
        expect(last_response.body).to include("Invalid submission")
      end

      it "returns 400 for non-multipart request" do
        post "/openrosa/submission", submission_xml, "CONTENT_TYPE" => "text/xml"

        expect(last_response.status).to eq(400)
      end
    end

    context "when handler raises error" do
      let(:app) do
        OpenRosa::Middleware.new do |config|
          config.forms = [sample_form_class]

          config.on_submission do |_submission|
            raise StandardError, "Database connection failed"
          end
        end
      end

      it "returns 500 error" do
        post "/openrosa/submission", build_multipart_params(submission_xml)

        expect(last_response.status).to eq(500)
        expect(last_response.body).to include("Server error")
        expect(last_response.body).to include("Database connection failed")
      end
    end
  end

  describe "GET /openrosa/manifests/:id" do
    let(:form_with_manifest) do
      Class.new(OpenRosa::Form) do
        form_id "survey_with_media"
        version "1.0.0"
        name "Survey with Media"
        download_url "https://example.com/forms/survey_with_media"
        manifest_url "https://example.com/manifests/survey_with_media"

        input :name, label: "Name", type: :string

        # Define manifest with media files
        # rubocop:disable Metrics/MethodLength
        def self.manifest
          @manifest ||= begin
            manifest = OpenRosa::Manifest.new
            manifest.add_media_file(
              OpenRosa::MediaFile.new(
                filename: "images/logo.png",
                hash: "md5:abc123",
                download_url: "https://example.com/media/logo.png"
              )
            )
            manifest.add_media_file(
              OpenRosa::MediaFile.new(
                filename: "audio/intro.mp3",
                hash: "md5:def456",
                download_url: "https://example.com/media/intro.mp3"
              )
            )
            manifest
          end
        end
        # rubocop:enable Metrics/MethodLength
      end
    end

    let(:app) do
      OpenRosa::Middleware.new do |config|
        config.forms = [form_with_manifest, sample_form_class]
      end
    end

    it "returns manifest XML for form with manifest" do
      get "/openrosa/manifests/survey_with_media"

      expect(last_response.status).to eq(200)
      expect(last_response.headers["Content-Type"]).to eq("text/xml; charset=utf-8")
      expect(last_response.headers["X-OpenRosa-Version"]).to eq("1.0")

      xml = last_response.body
      expect(xml).to include("<manifest")
      expect(xml).to include("<filename>images/logo.png</filename>")
      expect(xml).to include("<hash>md5:abc123</hash>")
      expect(xml).to include("<downloadUrl>https://example.com/media/logo.png</downloadUrl>")
      expect(xml).to include("<filename>audio/intro.mp3</filename>")
    end

    it "returns 404 for form without manifest" do
      get "/openrosa/manifests/survey_001"

      expect(last_response.status).to eq(404)
      expect(last_response.body).to include("Manifest not found")
    end

    it "returns 404 for non-existent form" do
      get "/openrosa/manifests/non_existent_form"

      expect(last_response.status).to eq(404)
      expect(last_response.body).to include("Form not found")
    end

    it "works with custom mount path" do
      middleware = OpenRosa::Middleware.new do |config|
        config.mount_path = "/custom"
        config.forms = [form_with_manifest]
      end

      env = Rack::MockRequest.env_for("/custom/manifests/survey_with_media")
      status, _, body = middleware.call(env)

      expect(status).to eq(200)
      xml = body.join
      expect(xml).to include("<manifest")
    end
  end

  describe "Authentication" do
    let(:submission_xml) do
      <<~XML
        <?xml version="1.0"?>
        <survey_001 id="survey_001">
          <name>John Doe</name>
          <age>30</age>
          <meta>
            <instanceID>uuid:12345678-1234-1234-1234-123456789012</instanceID>
          </meta>
        </survey_001>
      XML
    end

    context "without authentication configured" do
      let(:app) do
        OpenRosa::Middleware.new do |config|
          config.forms = [sample_form_class]
        end
      end

      it "allows access to formList" do
        get "/openrosa/formList"

        expect(last_response.status).to eq(200)
      end

      it "allows access to form download" do
        get "/openrosa/forms/survey_001"

        expect(last_response.status).to eq(200)
      end

      it "allows access to submission" do
        post "/openrosa/submission", build_multipart_params(submission_xml)

        expect(last_response.status).to eq(201)
      end
    end

    context "with authentication configured" do
      let(:app) do
        OpenRosa::Middleware.new do |config|
          config.forms = [sample_form_class]

          config.authenticate do |env|
            auth = Rack::Auth::Basic::Request.new(env)
            if auth.provided? && auth.basic? && auth.credentials
              username, password = auth.credentials
              # Simple authentication: username=admin, password=secret
              username == "admin" && password == "secret" ? { username: username } : nil
            end
          end
        end
      end

      it "returns 401 for formList without credentials" do
        get "/openrosa/formList"

        expect(last_response.status).to eq(401)
        expect(last_response.headers["WWW-Authenticate"]).to eq('Basic realm="OpenRosa"')
        expect(last_response.body).to eq("Unauthorized")
      end

      it "returns 401 for form download without credentials" do
        get "/openrosa/forms/survey_001"

        expect(last_response.status).to eq(401)
      end

      it "returns 401 for submission without credentials" do
        post "/openrosa/submission", build_multipart_params(submission_xml)

        expect(last_response.status).to eq(401)
      end

      it "allows access with valid credentials" do
        get "/openrosa/formList", {}, "HTTP_AUTHORIZATION" => "Basic #{["admin:secret"].pack("m0")}"

        expect(last_response.status).to eq(200)
        expect(last_response.body).to include("<xforms")
      end

      it "returns 401 with invalid credentials" do
        get "/openrosa/formList", {}, "HTTP_AUTHORIZATION" => "Basic #{["admin:wrong"].pack("m0")}"

        expect(last_response.status).to eq(401)
      end

      it "stores authenticated user in env" do
        received_env = nil

        # Define a custom app for this test
        test_app = OpenRosa::Middleware.new do |config|
          config.forms = [sample_form_class]

          config.authenticate do |env|
            received_env = env # Capture env for inspection
            auth = Rack::Auth::Basic::Request.new(env)
            if auth.provided? && auth.basic? && auth.credentials
              username, password = auth.credentials
              username == "admin" && password == "secret" ? { username: username, id: 123 } : nil
            end
          end
        end

        # Create environment manually
        env_hash = Rack::MockRequest.env_for(
          "/openrosa/submission",
          method: "POST",
          "HTTP_AUTHORIZATION" => "Basic #{["admin:secret"].pack("m0")}"
        )

        # Manually build multipart data
        boundary = "----WebKitFormBoundary#{SecureRandom.hex(16)}"
        body_parts = []
        body_parts << "--#{boundary}"
        body_parts << 'Content-Disposition: form-data; name="xml_submission_file"; filename="submission.xml"'
        body_parts << "Content-Type: text/xml"
        body_parts << ""
        body_parts << submission_xml
        body_parts << "--#{boundary}--"
        body = body_parts.join("\r\n")

        env_hash["CONTENT_TYPE"] = "multipart/form-data; boundary=#{boundary}"
        env_hash["CONTENT_LENGTH"] = body.bytesize.to_s
        env_hash["rack.input"] = StringIO.new(body)

        status, _headers, _body = test_app.call(env_hash)

        expect(status).to eq(201)
        expect(received_env["openrosa.authenticated_user"]).to eq({ username: "admin", id: 123 })
      end
    end

    context "with skip_authentication_for configured" do
      let(:app) do
        OpenRosa::Middleware.new do |config|
          config.forms = [sample_form_class]

          config.authenticate do |env|
            auth = Rack::Auth::Basic::Request.new(env)
            if auth.provided? && auth.basic? && auth.credentials
              username, password = auth.credentials
              username == "admin" && password == "secret" ? true : nil
            end
          end

          config.skip_authentication_for = ["/formList"]
        end
      end

      it "skips authentication for formList" do
        get "/openrosa/formList"

        expect(last_response.status).to eq(200)
      end

      it "requires authentication for form download" do
        get "/openrosa/forms/survey_001"

        expect(last_response.status).to eq(401)
      end

      it "requires authentication for submission" do
        post "/openrosa/submission", build_multipart_params(submission_xml)

        expect(last_response.status).to eq(401)
      end
    end

    context "with regex patterns in skip_authentication_for" do
      let(:app) do
        OpenRosa::Middleware.new do |config|
          config.forms = [sample_form_class]

          config.authenticate do |env|
            auth = Rack::Auth::Basic::Request.new(env)
            if auth.provided? && auth.basic? && auth.credentials
              username, password = auth.credentials
              username == "admin" && password == "secret" ? true : nil
            end
          end

          config.skip_authentication_for = [%r{/forms/}]
        end
      end

      it "skips authentication for paths matching regex" do
        get "/openrosa/forms/survey_001"

        expect(last_response.status).to eq(200)
      end

      it "requires authentication for non-matching paths" do
        get "/openrosa/formList"

        expect(last_response.status).to eq(401)
      end
    end

    context "with custom authentication realm" do
      let(:app) do
        OpenRosa::Middleware.new do |config|
          config.forms = [sample_form_class]
          config.authentication_realm = "My Custom Realm"

          config.authenticate do |_env|
            false
          end
        end
      end

      it "uses custom realm in WWW-Authenticate header" do
        get "/openrosa/formList"

        expect(last_response.status).to eq(401)
        expect(last_response.headers["WWW-Authenticate"]).to eq('Basic realm="My Custom Realm"')
      end
    end

    context "with token-based authentication" do
      let(:app) do
        OpenRosa::Middleware.new do |config|
          config.forms = [sample_form_class]

          config.authenticate do |env|
            request = Rack::Request.new(env)
            token = request.env["HTTP_AUTHORIZATION"]&.sub(/^Bearer /, "")
            token == "valid-token-12345" ? { token: token } : nil
          end
        end
      end

      it "returns 401 without token" do
        get "/openrosa/formList"

        expect(last_response.status).to eq(401)
      end

      it "allows access with valid token" do
        get "/openrosa/formList", {}, "HTTP_AUTHORIZATION" => "Bearer valid-token-12345"

        expect(last_response.status).to eq(200)
      end

      it "returns 401 with invalid token" do
        get "/openrosa/formList", {}, "HTTP_AUTHORIZATION" => "Bearer invalid-token"

        expect(last_response.status).to eq(401)
      end
    end
  end

  # Helper method to build multipart form data
  def build_multipart_params(xml_content)
    {
      "xml_submission_file" => Rack::Test::UploadedFile.new(
        StringIO.new(xml_content),
        "text/xml",
        original_filename: "submission.xml"
      )
    }
  end
end
