# frozen_string_literal: true

require "rack"

module OpenRosa
  # Rack middleware for OpenRosa endpoints
  #
  # Provides endpoints for:
  # - GET /formList - List available forms
  # - GET /forms/:id - Download a specific form as XForm XML
  # - POST /submission - Receive form submissions
  # - HEAD /submission - Pre-flight check for submissions
  #
  # Example usage:
  #   use OpenRosa::Middleware do |config|
  #     config.forms = [MyForm, AnotherForm]
  #     config.mount_path = "/openrosa"
  #
  #     # Handle submissions
  #     config.on_submission do |submission|
  #       # Save to database, process files, etc.
  #       MySubmission.create!(
  #         form_id: submission.form_id,
  #         data: submission.data,
  #         instance_id: submission.instance_id
  #       )
  #       "Thank you for your submission!"
  #     end
  #   end
  class Middleware # rubocop:disable Metrics/ClassLength
    OPENROSA_VERSION = "1.0"

    attr_reader :app, :config

    def initialize(app = nil, &block)
      @app = app
      @config = Configuration.new
      block&.call(@config)
    end

    def call(env)
      request = Rack::Request.new(env)

      return delegate_to_app(env) unless handle_request?(request)

      # Check authentication if configured
      return unauthorized_response unless authenticated?(env, request)

      route_request(request)
    end

    private

    def delegate_to_app(env)
      @app ? @app.call(env) : not_found_response
    end

    def handle_request?(request)
      @app.nil? || openrosa_path?(request.path_info)
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
    def route_request(request)
      path = request.path_info
      method = request.request_method

      case [method, path]
      when ["GET", "#{mount_path}/formList"]
        handle_form_list(request)
      when ["POST", "#{mount_path}/submission"]
        handle_submission(request)
      when ["HEAD", "#{mount_path}/submission"]
        handle_submission_head(request)
      else
        # Check for form download pattern (GET /forms/:id)
        if method == "GET" && (match = path.match(%r{^#{Regexp.escape(mount_path)}/forms/(.+)$}))
          handle_form_download(request, match[1])
        # Check for manifest download pattern (GET /manifests/:id)
        elsif method == "GET" && (match = path.match(%r{^#{Regexp.escape(mount_path)}/manifests/(.+)$}))
          handle_manifest(request, match[1])
        else
          delegate_to_app(request.env)
        end
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity

    def mount_path
      @config.mount_path
    end

    def openrosa_path?(path)
      path.start_with?(mount_path)
    end

    def handle_form_list(request)
      form_list = FormList.new(available_forms, form_list_options(request))
      openrosa_xml_response(form_list.to_xml)
    end

    def form_list_options(request)
      {
        form_id: request.params["formID"],
        verbose: request.params["verbose"] == "true",
        base_url: @config.base_url,
        mount_path: mount_path
      }
    end

    def handle_form_download(_request, form_id)
      form = find_form(form_id)
      return not_found_response unless form

      xml = form.to_xml

      openrosa_xml_response(xml)
    end

    def handle_manifest(_request, form_id)
      form = find_form(form_id)
      return not_found_response("Form not found") unless form

      # Check if the form has a manifest method
      return not_found_response("Manifest not found for this form") unless form.class.respond_to?(:manifest)

      manifest = form.class.manifest
      return not_found_response("Manifest not found for this form") if manifest.nil? || manifest.empty?

      xml = manifest.to_xml

      openrosa_xml_response(xml)
    end

    def available_forms
      @config.forms.map do |form_class|
        # If it's a class, instantiate it; otherwise use as-is
        form_class.is_a?(Class) ? form_class.new : form_class
      end
    end

    def find_form(form_id)
      available_forms.find { |form| form.form_id == form_id }
    end

    def openrosa_xml_response(xml)
      [
        200,
        {
          "Content-Type" => "text/xml; charset=utf-8",
          "X-OpenRosa-Version" => OPENROSA_VERSION,
          "Date" => Time.now.httpdate
        },
        [xml]
      ]
    end

    def handle_submission(request)
      submission = parse_submission(request)
      return submission if submission.is_a?(Array) # Error response

      message = process_submission(submission)
      return message if message.is_a?(Array) # Error response

      openrosa_submission_response(message || "Submission received successfully")
    end

    def parse_submission(request)
      Submission.parse(request)
    rescue Submission::ParseError => e
      error_response(400, "Invalid submission: #{e.message}")
    end

    def process_submission(submission)
      form_class = find_form_class_for_submission(submission)
      execute_submission_handler(form_class, submission)
    rescue StandardError => e
      error_response(500, "Server error: #{e.message}")
    end

    def find_form_class_for_submission(submission)
      @config.forms.find do |fc|
        form = fc.is_a?(Class) ? fc.new : fc
        form.form_id == submission.form_id
      end
    end

    def execute_submission_handler(form_class, submission)
      # Try form-specific handler first
      form_handler_result = form_class&.handle_submission(submission) if form_class

      if form_handler_result
        form_handler_result
      elsif @config.submission_handler
        @config.submission_handler.call(submission)
      else
        "Submission received successfully"
      end
    end

    def handle_submission_head(_request)
      # HEAD request for pre-flight check
      # Return max content length we'll accept (10MB default)
      max_size = @config.max_submission_size || 10_485_760

      [
        204,
        {
          "X-OpenRosa-Version" => OPENROSA_VERSION,
          "X-OpenRosa-Accept-Content-Length" => max_size.to_s,
          "Date" => Time.now.httpdate
        },
        []
      ]
    end

    def openrosa_submission_response(message)
      xml = build_openrosa_response_xml(message)

      [
        201,
        {
          "Content-Type" => "text/xml; charset=utf-8",
          "X-OpenRosa-Version" => OPENROSA_VERSION,
          "Date" => Time.now.httpdate
        },
        [xml]
      ]
    end

    def build_openrosa_response_xml(message)
      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml.OpenRosaResponse(xmlns: "http://openrosa.org/http/response") do
          xml.message message
        end
      end

      builder.to_xml
    end

    def error_response(status, message)
      [
        status,
        {
          "Content-Type" => "text/plain",
          "X-OpenRosa-Version" => OPENROSA_VERSION,
          "Date" => Time.now.httpdate
        },
        [message]
      ]
    end

    def not_found_response(message = "Not Found")
      [
        404,
        { "Content-Type" => "text/plain" },
        [message]
      ]
    end

    def authenticated?(env, request)
      # No authentication handler configured = allow all requests
      return true unless @config.authentication_handler

      # Check if this path should skip authentication
      return true if skip_authentication?(request.path_info)

      # Call the authentication handler
      result = @config.authentication_handler.call(env)

      # Store the authenticated user/result in env for later use
      env["openrosa.authenticated_user"] = result if result

      # Return true if result is truthy (user object, true, etc.)
      !!result
    end

    def skip_authentication?(path)
      @config.skip_authentication_for.any? do |skip_path|
        if skip_path.is_a?(Regexp)
          path =~ skip_path
        else
          path == normalize_skip_path(skip_path)
        end
      end
    end

    def normalize_skip_path(path)
      # Ensure skip path includes mount_path if it's a relative path
      return path if path.start_with?(mount_path)

      "#{mount_path}#{path}"
    end

    def unauthorized_response
      [
        401,
        {
          "Content-Type" => "text/plain",
          "WWW-Authenticate" => "Basic realm=\"#{@config.authentication_realm}\"",
          "X-OpenRosa-Version" => OPENROSA_VERSION,
          "Date" => Time.now.httpdate
        },
        ["Unauthorized"]
      ]
    end

    # Configuration object for the middleware
    class Configuration
      attr_accessor :forms, :mount_path, :base_url, :submission_handler, :max_submission_size,
                    :authentication_handler, :skip_authentication_for, :authentication_realm

      def initialize
        @forms = []
        @mount_path = "/openrosa"
        @base_url = nil
        @submission_handler = nil
        @max_submission_size = 10_485_760 # 10MB default
        @authentication_handler = nil
        @skip_authentication_for = []
        @authentication_realm = "OpenRosa"
      end

      # Set the submission handler callback
      #
      # @yield [submission] The parsed submission
      # @yieldparam submission [Submission] The submission object
      # @yieldreturn [String, nil] Optional success message
      def on_submission(&block)
        @submission_handler = block
      end

      # Set the authentication handler callback
      #
      # @yield [env] The Rack environment hash
      # @yieldparam env [Hash] The Rack environment
      # @yieldreturn [Object, true, false, nil] Return truthy to authenticate, falsy to deny
      #
      # Example:
      #   config.authenticate do |env|
      #     request = Rack::Request.new(env)
      #     auth = Rack::Auth::Basic::Request.new(env)
      #     if auth.provided? && auth.basic?
      #       username, password = auth.credentials
      #       User.authenticate(username, password) # Returns user object or nil
      #     end
      #   end
      def authenticate(&block)
        @authentication_handler = block
      end
    end
  end
end
