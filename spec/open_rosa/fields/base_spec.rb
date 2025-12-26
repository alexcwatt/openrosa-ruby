# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenRosa::Fields::Base do
  describe "initialization" do
    it "accepts a name parameter" do
      field = OpenRosa::Fields::Base.new(:customer_name)
      expect(field.name).to eq(:customer_name)
    end

    it "accepts label option" do
      field = OpenRosa::Fields::Base.new(:age, label: "Your Age")
      expect(field.label).to eq("Your Age")
    end

    it "accepts hint option" do
      field = OpenRosa::Fields::Base.new(:email, hint: "Enter your email address")
      expect(field.hint).to eq("Enter your email address")
    end

    it "accepts required option" do
      field = OpenRosa::Fields::Base.new(:name, required: true)
      expect(field.required).to eq(true)
    end

    it "defaults required to false" do
      field = OpenRosa::Fields::Base.new(:optional_field)
      expect(field.required).to eq(false)
    end

    it "accepts default option" do
      field = OpenRosa::Fields::Base.new(:country, default: "USA")
      expect(field.default).to eq("USA")
    end
  end

  describe "attributes" do
    let(:field) do
      OpenRosa::Fields::Base.new(
        :test_field,
        label: "Test Field",
        hint: "A test",
        required: true,
        default: "default_value"
      )
    end

    it "provides access to name" do
      expect(field.name).to eq(:test_field)
    end

    it "provides access to label" do
      expect(field.label).to eq("Test Field")
    end

    it "provides access to hint" do
      expect(field.hint).to eq("A test")
    end

    it "provides access to required" do
      expect(field.required).to eq(true)
    end

    it "provides access to default" do
      expect(field.default).to eq("default_value")
    end
  end
end
