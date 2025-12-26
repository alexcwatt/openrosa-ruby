# frozen_string_literal: true

# Example of how to integrate OpenRosa middleware in a Rails application
#
# Add this to your Rails config/application.rb or config/environments/production.rb

# Step 1: Define your forms (perhaps in app/forms/)
class MySurveyForm < OpenRosa::Form
  form_id "my_survey"
  version "1.0.0"
  name "My Survey"
  download_url "https://myapp.com/openrosa/forms/my_survey"

  input :name, label: "Name", type: :string, required: true
  input :age, label: "Age", type: :int
  select1 :gender, label: "Gender", choices: ["Male", "Female", "Other"]

  # Option A: Form-specific submission handler
  on_submit do |submission|
    # Handle submissions for this specific form
    Survey.create!(
      instance_id: submission.instance_id,
      name: submission.data["name"],
      age: submission.data["age"],
      gender: submission.data["gender"],
      submitted_at: submission.metadata[:timeEnd]
    )

    "Thank you for completing the survey!"
  end
end

# Step 2: Add middleware to your Rails application
# In config/application.rb:
#
# module MyApp
#   class Application < Rails::Application
#     # ... other config ...
#
#     config.middleware.use OpenRosa::Middleware do |config|
#       config.forms = [MySurveyForm]
#       config.mount_path = "/openrosa"
#
#       # Option B: Global submission handler (for all forms)
#       config.on_submission do |submission|
#         # Generic handler for all form submissions
#         FormSubmission.create!(
#           form_id: submission.form_id,
#           instance_id: submission.instance_id,
#           data: submission.data,
#           metadata: submission.metadata,
#           raw_xml: submission.raw_xml
#         )
#
#         # Handle file attachments
#         submission.attachments.each do |attachment|
#           # Save to ActiveStorage or file system
#           record = FormSubmission.find_by(instance_id: submission.instance_id)
#           record.attachments.attach(
#             io: StringIO.new(attachment.read),
#             filename: attachment.filename,
#             content_type: attachment.content_type
#           )
#         end
#
#         "Submission received successfully!"
#       end
#     end
#   end
# end

# Alternative: Use an initializer
# Create config/initializers/openrosa.rb:
#
# Rails.application.config.middleware.use OpenRosa::Middleware do |config|
#   # Load all form classes from app/forms
#   config.forms = Dir[Rails.root.join("app/forms/**/*.rb")].map do |file|
#     require file
#     # Extract class name from file and constantize
#     File.basename(file, ".rb").camelize.constantize
#   end
#
#   config.mount_path = "/openrosa"
#
#   # Global submission handler
#   config.on_submission do |submission|
#     # Process submission...
#     Rails.logger.info "Received submission for form: #{submission.form_id}"
#
#     FormSubmission.create!(
#       form_id: submission.form_id,
#       instance_id: submission.instance_id,
#       payload: submission.data
#     )
#   end
# end

# Step 3: Endpoints will be available at:
#   GET  /openrosa/formList          - List all forms
#   GET  /openrosa/forms/:id         - Download specific form XForm XML
#   HEAD /openrosa/submission        - Pre-flight check for submissions
#   POST /openrosa/submission        - Receive form submissions
#
# These endpoints will properly return XML with OpenRosa headers:
#   - Content-Type: text/xml; charset=utf-8
#   - X-OpenRosa-Version: 1.0
#   - Date: [current date in HTTP format]

# Step 4: (Optional) Add authentication
# You can add authentication by placing another middleware before OpenRosa:
#
# Rails.application.config.middleware.insert_before(
#   OpenRosa::Middleware,
#   MyAuthMiddleware
# )
#
# Or use Rails controllers instead for more control:
# Create app/controllers/openrosa_controller.rb:
#
# class OpenrosaController < ApplicationController
#   before_action :authenticate_user!
#
#   def form_list
#     form_id = params[:formID]
#     verbose = params[:verbose] == "true"
#
#     forms = [MySurveyForm.new]
#     form_list = OpenRosa::FormList.new(forms, form_id: form_id, verbose: verbose)
#
#     render xml: form_list.to_xml, content_type: "text/xml; charset=utf-8"
#     response.headers["X-OpenRosa-Version"] = "1.0"
#   end
#
#   def form_download
#     form_class = find_form_class(params[:id])
#     return head :not_found unless form_class
#
#     form = form_class.new
#     render xml: form.to_xml, content_type: "text/xml; charset=utf-8"
#     response.headers["X-OpenRosa-Version"] = "1.0"
#   end
#
#   private
#
#   def find_form_class(form_id)
#     [MySurveyForm].find { |fc| fc.new.form_id == form_id }
#   end
# end
#
# And in config/routes.rb:
#   get "/openrosa/formList", to: "openrosa#form_list"
#   get "/openrosa/forms/:id", to: "openrosa#form_download"
