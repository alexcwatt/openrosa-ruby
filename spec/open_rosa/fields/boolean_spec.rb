# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenRosa::Fields::Boolean do
  describe "initialization" do
    it "inherits from Base" do
      field = OpenRosa::Fields::Boolean.new(:is_active)
      expect(field).to be_a(OpenRosa::Fields::Base)
    end

    it "accepts appearance option" do
      field = OpenRosa::Fields::Boolean.new(:confirmed, appearance: "minimal")
      expect(field.appearance).to eq("minimal")
    end

    it "defaults appearance to nil" do
      field = OpenRosa::Fields::Boolean.new(:is_active)
      expect(field.appearance).to be_nil
    end
  end

  describe "boolean field with standard attributes" do
    let(:field) do
      OpenRosa::Fields::Boolean.new(
        :terms_accepted,
        label: "Do you accept the terms?",
        hint: "Check this box to accept",
        required: true,
        default: false
      )
    end

    it "stores all attributes correctly" do
      expect(field.name).to eq(:terms_accepted)
      expect(field.label).to eq("Do you accept the terms?")
      expect(field.hint).to eq("Check this box to accept")
      expect(field.required).to eq(true)
      expect(field.default).to eq(false)
    end
  end

  describe "boolean field with appearance" do
    let(:field) do
      OpenRosa::Fields::Boolean.new(
        :newsletter_subscribe,
        label: "Subscribe to newsletter?",
        appearance: "minimal",
        required: false
      )
    end

    it "stores all attributes correctly" do
      expect(field.name).to eq(:newsletter_subscribe)
      expect(field.label).to eq("Subscribe to newsletter?")
      expect(field.appearance).to eq("minimal")
      expect(field.required).to eq(false)
    end
  end

  describe "boolean field with true default" do
    let(:field) do
      OpenRosa::Fields::Boolean.new(
        :opt_in,
        label: "Opt in to notifications",
        default: true
      )
    end

    it "stores true default value" do
      expect(field.default).to eq(true)
    end
  end
end
