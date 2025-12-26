# OpenRosa Ruby

A Ruby gem for building [OpenRosa](https://docs.getodk.org/openrosa/) compliant form servers. Define forms with a clean DSL, serve them via Rack middleware, and handle submissions from mobile data collection apps like ODK Collect.

## Installation

Add to your Gemfile:

```ruby
gem "open_rosa"
```

Or install directly:

```bash
gem install open_rosa
```

## Quick Start

### 1. Define a Form

```ruby
class SurveyForm < OpenRosa::Form
  form_id "my_survey"
  version "1.0.0"
  name "Customer Survey"

  input :name, label: "Your Name", type: :string, required: true
  input :email, label: "Email", type: :string
  input :age, label: "Age", type: :int

  select1 :satisfaction,
          label: "How satisfied are you?",
          choices: {
            "very_satisfied" => "Very Satisfied",
            "satisfied" => "Satisfied",
            "neutral" => "Neutral",
            "dissatisfied" => "Dissatisfied"
          },
          required: true

  boolean :would_recommend, label: "Would you recommend us?"

  input :comments, label: "Additional Comments", type: :string
end
```

### 2. Mount the Middleware

```ruby
# config.ru (Rack) or config/application.rb (Rails)
use OpenRosa::Middleware do |config|
  config.base_url = "https://example.com"
  config.mount_path = "/openrosa"
  config.forms = [SurveyForm]

  config.on_submission do |submission|
    puts "Received: #{submission.form_id}"
    puts "Data: #{submission.data}"
    "Thank you for your submission!"
  end
end
```

### 3. Available Endpoints

The middleware provides these OpenRosa-compliant endpoints:

| Method | Path | Description |
|--------|------|-------------|
| GET | `/openrosa/formList` | List available forms |
| GET | `/openrosa/forms/:id` | Download form XForm XML |
| HEAD | `/openrosa/submission` | Pre-flight check |
| POST | `/openrosa/submission` | Submit form data |

## Field Types

### input

Text, numeric, and date inputs:

```ruby
input :name, label: "Name", type: :string, required: true
input :age, label: "Age", type: :int
input :temperature, label: "Temperature", type: :decimal
input :birthdate, label: "Birth Date", type: :date
input :appointment, label: "Appointment", type: :dateTime
input :start_time, label: "Start Time", type: :time
```

### select1

Single-choice selection:

```ruby
select1 :color,
        label: "Favorite Color",
        choices: { "r" => "Red", "g" => "Green", "b" => "Blue" },
        appearance: "minimal"
```

### select

Multiple-choice selection:

```ruby
select :topics,
       label: "Topics of Interest",
       choices: ["Technology", "Science", "Art", "Music"]
```

### boolean

Yes/no questions:

```ruby
boolean :agree, label: "I agree to the terms", appearance: "checkbox"
```

### range

Numeric range slider:

```ruby
range :rating,
      label: "Rate 1-10",
      start: 1,
      end: 10,
      step: 1,
      type: :int
```

### upload

File uploads:

```ruby
upload :photo, label: "Take a photo", mediatype: "image/*"
upload :signature, label: "Signature", mediatype: "image/*", appearance: "signature"
upload :audio, label: "Record audio", mediatype: "audio/*"
```

### trigger

Action button (acknowledge/confirm):

```ruby
trigger :acknowledge, label: "I have read and understood", appearance: "acknowledge"
```

### group

Logical grouping of fields:

```ruby
group :contact_info, label: "Contact Information" do
  input :phone, label: "Phone", type: :string
  input :address, label: "Address", type: :string
end
```

### repeat

Repeatable field groups:

```ruby
repeat :household_members, label: "Household Members" do
  input :member_name, label: "Name", type: :string
  input :member_age, label: "Age", type: :int
end
```

## Form Metadata

```ruby
class MyForm < OpenRosa::Form
  form_id "unique_form_id"           # Required: unique identifier
  version "1.0.0"                    # Form version
  name "Human Readable Name"         # Display name
  description_text "Form description"
  download_url "https://..."         # Optional: auto-generated from base_url if not set
  manifest_url "https://..."         # URL for media manifest (if needed)
end
```

## Handling Submissions

### Global Handler (Middleware)

```ruby
use OpenRosa::Middleware do |config|
  config.forms = [MyForm]

  config.on_submission do |submission|
    # submission.form_id      - Form identifier
    # submission.instance_id  - Unique submission ID
    # submission.data         - Hash of field values
    # submission.metadata     - Submission metadata (timeStart, timeEnd, etc.)
    # submission.raw_xml      - Original XML string
    # submission.attachments  - Array of uploaded files

    MyModel.create!(
      form_id: submission.form_id,
      data: submission.data
    )

    submission.attachments.each do |file|
      # file.filename, file.content_type, file.read, file.size
      save_file(file)
    end

    "Submission received!"  # Optional success message
  end
end
```

### Per-Form Handler

```ruby
class MyForm < OpenRosa::Form
  form_id "my_form"

  input :name, label: "Name", type: :string

  on_submit do |submission|
    # Handle submissions for this specific form
    Record.create!(name: submission.data["name"])
    "Thank you!"
  end
end
```

## Rails Integration

```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    config.middleware.use OpenRosa::Middleware do |config|
      config.forms = [SurveyForm, FeedbackForm]
      config.mount_path = "/openrosa"

      config.on_submission do |submission|
        FormSubmission.create!(
          form_id: submission.form_id,
          instance_id: submission.instance_id,
          data: submission.data
        )
      end
    end
  end
end
```

## Generating XForm XML

You can generate the XForm XML directly:

```ruby
xml = SurveyForm.to_xml
# => Complete XForm XML string

hash = SurveyForm.form_hash
# => "md5:abc123..." (for change detection)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests and linter.

```bash
bin/setup
rake
```

Use `bin/console` for an interactive prompt to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/alexcwatt/openrosa-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
