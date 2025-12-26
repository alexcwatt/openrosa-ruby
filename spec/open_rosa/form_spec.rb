# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenRosa::Form do
  describe "class methods" do
    let(:test_form_class) do
      Class.new(OpenRosa::Form) do
        form_id "test_form_001"
        version "1.0.0"
        name "Test Survey Form"
        description_text "A detailed survey form for testing purposes"
        description_url "https://example.com/forms/test_form_001/details"
      end
    end

    it "allows setting form_id" do
      expect(test_form_class.form_id).to eq("test_form_001")
    end

    it "allows setting version" do
      expect(test_form_class.version).to eq("1.0.0")
    end

    it "allows setting name" do
      expect(test_form_class.name).to eq("Test Survey Form")
    end

    it "allows setting description_text" do
      expect(test_form_class.description_text).to eq("A detailed survey form for testing purposes")
    end

    it "allows setting description_url" do
      expect(test_form_class.description_url).to eq("https://example.com/forms/test_form_001/details")
    end

    it "calculates form_hash from form content" do
      hash = test_form_class.form_hash
      expect(hash).to start_with("md5:")
      expect(hash.length).to eq(36) # "md5:" + 32 hex characters
    end

    it "generates XForm XML" do
      xml = test_form_class.to_xml
      expect(xml).to include('<?xml version="1.0" encoding="UTF-8"?>')
      expect(xml).to include("<html")
      expect(xml).to include('xmlns="http://www.w3.org/2002/xforms"')
      expect(xml).to include('<title xmlns="http://www.w3.org/1999/xhtml">Test Survey Form</title>')
    end
  end

  describe "instance methods" do
    let(:test_form_class) do
      Class.new(OpenRosa::Form) do
        form_id "survey_v2"
        version "2.1.5"
        name "Customer Feedback Survey"
        description_text "Help us improve by providing your feedback"
        description_url "https://example.com/surveys/feedback/info"
      end
    end

    let(:form_instance) { test_form_class.new }

    it "provides access to form_id from instance" do
      expect(form_instance.form_id).to eq("survey_v2")
    end

    it "provides access to version from instance" do
      expect(form_instance.version).to eq("2.1.5")
    end

    it "provides access to name from instance" do
      expect(form_instance.name).to eq("Customer Feedback Survey")
    end

    it "provides access to description_text from instance" do
      expect(form_instance.description_text).to eq("Help us improve by providing your feedback")
    end

    it "provides access to description_url from instance" do
      expect(form_instance.description_url).to eq("https://example.com/surveys/feedback/info")
    end

    it "provides access to form_hash from instance" do
      hash = form_instance.form_hash
      expect(hash).to start_with("md5:")
      expect(hash.length).to eq(36)
    end

    it "generates XForm XML from instance" do
      xml = form_instance.to_xml
      expect(xml).to include('<?xml version="1.0" encoding="UTF-8"?>')
      expect(xml).to include('<title xmlns="http://www.w3.org/1999/xhtml">Customer Feedback Survey</title>')
    end
  end

  describe "without configuration" do
    let(:unconfigured_form_class) { Class.new(OpenRosa::Form) }
    let(:form_instance) { unconfigured_form_class.new }

    it "returns nil for form_id when not set" do
      expect(unconfigured_form_class.form_id).to be_nil
    end

    it "returns nil for version when not set" do
      expect(unconfigured_form_class.version).to be_nil
    end

    it "returns nil for name when not set" do
      expect(unconfigured_form_class.name).to be_nil
    end

    it "returns nil for description_text when not set" do
      expect(unconfigured_form_class.description_text).to be_nil
    end

    it "returns nil for description_url when not set" do
      expect(unconfigured_form_class.description_url).to be_nil
    end

    it "returns nil for form_hash when form_id not set" do
      # Cannot generate hash without form_id
      expect(unconfigured_form_class.form_id).to be_nil
      expect { unconfigured_form_class.form_hash }.to raise_error(NoMethodError)
    end

    it "returns nil from instance when not configured" do
      expect(form_instance.form_id).to be_nil
      expect(form_instance.version).to be_nil
      expect(form_instance.name).to be_nil
      expect(form_instance.description_text).to be_nil
      expect(form_instance.description_url).to be_nil
      # Cannot generate hash without form_id
      expect { form_instance.form_hash }.to raise_error(NoMethodError)
    end
  end

  describe "field DSL" do
    let(:form_with_fields) do
      Class.new(OpenRosa::Form) do
        form_id "survey_001"
        version "1.0.0"

        input :customer_name, label: "Customer Name", type: :string, required: true
        input :age, label: "Age", type: :int
        select1 :satisfaction, label: "Satisfaction Level", choices: ["Good", "Bad"]
        select :interests, label: "Interests", choices: ["Sports", "Music"]
        boolean :terms_accepted, label: "Accept Terms", required: true
        upload :photo, label: "Upload Photo", mediatype: "image/*"
        range :rating, label: "Rating", start: 1, end: 10
        trigger :acknowledge, label: "I Acknowledge"
      end
    end

    it "collects input fields" do
      fields = form_with_fields.fields
      input_fields = fields.select { |f| f.is_a?(OpenRosa::Fields::Input) }
      expect(input_fields.size).to eq(2)
      expect(input_fields[0].name).to eq(:customer_name)
      expect(input_fields[0].label).to eq("Customer Name")
      expect(input_fields[0].required).to eq(true)
      expect(input_fields[1].name).to eq(:age)
    end

    it "collects select1 fields" do
      fields = form_with_fields.fields
      select1_fields = fields.select { |f| f.is_a?(OpenRosa::Fields::Select1) }
      expect(select1_fields.size).to eq(1)
      expect(select1_fields[0].name).to eq(:satisfaction)
      expect(select1_fields[0].choices).to eq(["Good", "Bad"])
    end

    it "collects select fields" do
      fields = form_with_fields.fields
      select_fields = fields.select { |f| f.is_a?(OpenRosa::Fields::Select) }
      expect(select_fields.size).to eq(1)
      expect(select_fields[0].name).to eq(:interests)
    end

    it "collects boolean fields" do
      fields = form_with_fields.fields
      boolean_fields = fields.select { |f| f.is_a?(OpenRosa::Fields::Boolean) }
      expect(boolean_fields.size).to eq(1)
      expect(boolean_fields[0].name).to eq(:terms_accepted)
    end

    it "collects upload fields" do
      fields = form_with_fields.fields
      upload_fields = fields.select { |f| f.is_a?(OpenRosa::Fields::Upload) }
      expect(upload_fields.size).to eq(1)
      expect(upload_fields[0].name).to eq(:photo)
    end

    it "collects range fields" do
      fields = form_with_fields.fields
      range_fields = fields.select { |f| f.is_a?(OpenRosa::Fields::Range) }
      expect(range_fields.size).to eq(1)
      expect(range_fields[0].name).to eq(:rating)
    end

    it "collects trigger fields" do
      fields = form_with_fields.fields
      trigger_fields = fields.select { |f| f.is_a?(OpenRosa::Fields::Trigger) }
      expect(trigger_fields.size).to eq(1)
      expect(trigger_fields[0].name).to eq(:acknowledge)
    end

    it "maintains field order" do
      fields = form_with_fields.fields
      expect(fields.size).to eq(8)
      expect(fields[0].name).to eq(:customer_name)
      expect(fields[1].name).to eq(:age)
      expect(fields[2].name).to eq(:satisfaction)
      expect(fields[3].name).to eq(:interests)
      expect(fields[4].name).to eq(:terms_accepted)
      expect(fields[5].name).to eq(:photo)
      expect(fields[6].name).to eq(:rating)
      expect(fields[7].name).to eq(:acknowledge)
    end

    it "provides access to fields from instance" do
      instance = form_with_fields.new
      expect(instance.fields.size).to eq(8)
      expect(instance.fields[0].name).to eq(:customer_name)
    end
  end

  describe "group DSL" do
    let(:form_with_groups) do
      Class.new(OpenRosa::Form) do
        form_id "grouped_form"

        input :name, label: "Name", type: :string

        group :address, label: "Address Information" do
          input :street, label: "Street", type: :string
          input :city, label: "City", type: :string
          input :zip, label: "ZIP", type: :string
        end

        input :email, label: "Email", type: :string
      end
    end

    it "creates a group field" do
      fields = form_with_groups.fields
      groups = fields.select { |f| f.is_a?(OpenRosa::Fields::Group) }
      expect(groups.size).to eq(1)
      expect(groups[0].name).to eq(:address)
      expect(groups[0].label).to eq("Address Information")
    end

    it "collects nested fields in group" do
      fields = form_with_groups.fields
      group = fields.find { |f| f.is_a?(OpenRosa::Fields::Group) }
      expect(group.fields.size).to eq(3)
      expect(group.fields[0].name).to eq(:street)
      expect(group.fields[1].name).to eq(:city)
      expect(group.fields[2].name).to eq(:zip)
    end

    it "maintains correct field order with groups" do
      fields = form_with_groups.fields
      expect(fields.size).to eq(3) # name, address group, email
      expect(fields[0].name).to eq(:name)
      expect(fields[1].name).to eq(:address)
      expect(fields[2].name).to eq(:email)
    end
  end

  describe "repeat DSL" do
    let(:form_with_repeats) do
      Class.new(OpenRosa::Form) do
        form_id "order_form"

        input :customer_name, label: "Customer Name", type: :string

        repeat :items, label: "Order Items" do
          input :product_name, label: "Product", type: :string
          input :quantity, label: "Quantity", type: :int
          input :price, label: "Price", type: :decimal
        end
      end
    end

    it "creates a repeat field" do
      fields = form_with_repeats.fields
      repeats = fields.select { |f| f.is_a?(OpenRosa::Fields::Repeat) }
      expect(repeats.size).to eq(1)
      expect(repeats[0].name).to eq(:items)
      expect(repeats[0].label).to eq("Order Items")
    end

    it "collects nested fields in repeat" do
      fields = form_with_repeats.fields
      repeat_field = fields.find { |f| f.is_a?(OpenRosa::Fields::Repeat) }
      expect(repeat_field.fields.size).to eq(3)
      expect(repeat_field.fields[0].name).to eq(:product_name)
      expect(repeat_field.fields[1].name).to eq(:quantity)
      expect(repeat_field.fields[2].name).to eq(:price)
    end
  end
end
