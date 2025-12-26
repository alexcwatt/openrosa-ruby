# frozen_string_literal: true

# Example Rack application demonstrating OpenRosa middleware usage
#
# Run this with: rackup examples/rack_app.rb
# Then access:
#   - http://localhost:9292/openrosa/formList
#   - http://localhost:9292/openrosa/forms/customer_survey

require_relative "../lib/open_rosa"

# Define a sample customer survey form
class CustomerSurvey < OpenRosa::Form
  form_id "customer_survey"
  version "1.0.0"
  name "Customer Satisfaction Survey"
  description_text "Please rate your experience with our service"
  download_url "http://localhost:9292/openrosa/forms/customer_survey"

  # Customer information
  input :customer_name,
        label: "Your Name",
        type: :string,
        required: true

  input :customer_email,
        label: "Email Address",
        type: :string

  # Satisfaction rating
  select1 :satisfaction,
          label: "Overall Satisfaction",
          choices: {
            "very_satisfied" => "Very Satisfied",
            "satisfied" => "Satisfied",
            "neutral" => "Neutral",
            "dissatisfied" => "Dissatisfied",
            "very_dissatisfied" => "Very Dissatisfied"
          },
          required: true,
          appearance: "minimal"

  # Rating scale
  range :service_rating,
        label: "Rate our service (1-10)",
        start: 1,
        end: 10,
        step: 1,
        type: :int

  # Comments
  input :comments,
        label: "Additional Comments",
        type: :string

  # Optional photo
  upload :photo,
         label: "Upload a photo (optional)",
         mediatype: "image/*"

  # Visit date
  input :visit_date,
        label: "Date of Visit",
        type: :date

  # Would recommend
  boolean :would_recommend,
          label: "Would you recommend us to a friend?",
          appearance: "checkbox"
end

# Define an employee feedback form
class EmployeeFeedback < OpenRosa::Form
  form_id "employee_feedback"
  version "2.0.0"
  name "Employee Feedback Form"
  description_text "Quarterly employee feedback survey"
  download_url "http://localhost:9292/openrosa/forms/employee_feedback"

  group :personal_info, label: "Personal Information" do
    input :employee_id,
          label: "Employee ID",
          type: :string,
          required: true

    input :department,
          label: "Department",
          type: :string
  end

  group :feedback, label: "Feedback" do
    select :areas_improvement,
           label: "Areas for Improvement",
           choices: [
             "Communication",
             "Work-Life Balance",
             "Career Development",
             "Management",
             "Compensation"
           ]

    input :suggestions,
          label: "Your Suggestions",
          type: :string
  end
end

# Create a simple Rack app that responds to non-OpenRosa paths
app = lambda do |env|
  request = Rack::Request.new(env)

  if request.path == "/"
    [
      200,
      { "Content-Type" => "text/html" },
      [<<~HTML]
        <!DOCTYPE html>
        <html>
          <head><title>OpenRosa Example Server</title></head>
          <body>
            <h1>OpenRosa Example Server</h1>
            <h2>Available Endpoints:</h2>
            <ul>
              <li><a href="/openrosa/formList">GET /openrosa/formList</a> - List all forms</li>
              <li><a href="/openrosa/formList?formID=customer_survey">GET /openrosa/formList?formID=customer_survey</a> - Filter by form ID</li>
              <li><a href="/openrosa/formList?verbose=true">GET /openrosa/formList?verbose=true</a> - Verbose mode</li>
              <li><a href="/openrosa/forms/customer_survey">GET /openrosa/forms/customer_survey</a> - Download Customer Survey form</li>
              <li><a href="/openrosa/forms/employee_feedback">GET /openrosa/forms/employee_feedback</a> - Download Employee Feedback form</li>
              <li>HEAD /openrosa/submission - Pre-flight check for submissions</li>
              <li>POST /openrosa/submission - Submit form data (multipart/form-data)</li>
            </ul>
            <h2>Available Forms:</h2>
            <ul>
              <li><strong>customer_survey</strong> - Customer Satisfaction Survey (v1.0.0)</li>
              <li><strong>employee_feedback</strong> - Employee Feedback Form (v2.0.0)</li>
            </ul>
          </body>
        </html>
      HTML
    ]
  else
    [404, { "Content-Type" => "text/plain" }, ["Not Found"]]
  end
end

# Wrap the app with OpenRosa middleware
use OpenRosa::Middleware do |config|
  config.forms = [CustomerSurvey, EmployeeFeedback]
  config.mount_path = "/openrosa"

  # Handle form submissions
  config.on_submission do |submission|
    # Print submission details to console
    puts "\n=== Form Submission Received ==="
    puts "Form ID: #{submission.form_id}"
    puts "Instance ID: #{submission.instance_id}"
    puts "Submitted at: #{submission.metadata[:timeEnd]}"
    puts "Data:"
    submission.data.each do |key, value|
      puts "  #{key}: #{value}"
    end

    if submission.attachments.any?
      puts "Attachments:"
      submission.attachments.each do |att|
        puts "  - #{att.filename} (#{att.content_type}, #{att.size} bytes)"
        # In a real app, you'd save these files:
        # File.write("uploads/#{att.filename}", att.read)
      end
    end
    puts "================================\n"

    # Return a custom success message
    "Thank you! Your #{submission.form_id} submission has been received."
  end
end

run app
