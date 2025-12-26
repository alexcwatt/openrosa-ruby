# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenRosa::Fields::Select do
  describe "initialization" do
    it "inherits from Base" do
      field = OpenRosa::Fields::Select.new(:interests, choices: ["Sports", "Music"])
      expect(field).to be_a(OpenRosa::Fields::Base)
    end

    it "accepts choices option as array" do
      field = OpenRosa::Fields::Select.new(:interests, choices: ["Sports", "Music", "Reading"])
      expect(field.choices).to eq(["Sports", "Music", "Reading"])
    end

    it "accepts choices option as hash" do
      field = OpenRosa::Fields::Select.new(
        :features,
        choices: { "wifi" => "WiFi", "parking" => "Parking", "pool" => "Swimming Pool" }
      )
      expect(field.choices).to eq({ "wifi" => "WiFi", "parking" => "Parking", "pool" => "Swimming Pool" })
    end

    it "accepts appearance option" do
      field = OpenRosa::Fields::Select.new(:options, choices: ["A", "B"], appearance: "compact")
      expect(field.appearance).to eq("compact")
    end

    it "defaults appearance to nil" do
      field = OpenRosa::Fields::Select.new(:options, choices: ["A", "B"])
      expect(field.appearance).to be_nil
    end
  end

  describe "with array choices" do
    let(:field) do
      OpenRosa::Fields::Select.new(
        :interests,
        label: "Select your interests",
        hint: "Choose all that apply",
        choices: ["Sports", "Music", "Reading", "Travel"],
        required: false
      )
    end

    it "stores all attributes correctly" do
      expect(field.name).to eq(:interests)
      expect(field.label).to eq("Select your interests")
      expect(field.hint).to eq("Choose all that apply")
      expect(field.choices).to eq(["Sports", "Music", "Reading", "Travel"])
      expect(field.required).to eq(false)
    end
  end

  describe "with hash choices (value => label)" do
    let(:field) do
      OpenRosa::Fields::Select.new(
        :amenities,
        label: "Select amenities",
        choices: { "ac" => "Air Conditioning", "heat" => "Heating", "wifi" => "WiFi" },
        appearance: "minimal"
      )
    end

    it "stores all attributes correctly" do
      expect(field.name).to eq(:amenities)
      expect(field.label).to eq("Select amenities")
      expect(field.choices).to eq({ "ac" => "Air Conditioning", "heat" => "Heating", "wifi" => "WiFi" })
      expect(field.appearance).to eq("minimal")
    end
  end

  describe "validation" do
    it "raises error when choices is missing" do
      expect do
        OpenRosa::Fields::Select.new(:field)
      end.to raise_error(ArgumentError, "choices is required for Select field")
    end

    it "raises error when choices is nil" do
      expect do
        OpenRosa::Fields::Select.new(:field, choices: nil)
      end.to raise_error(ArgumentError, "choices is required for Select field")
    end

    it "raises error when choices is empty array" do
      expect do
        OpenRosa::Fields::Select.new(:field, choices: [])
      end.to raise_error(ArgumentError, "choices cannot be empty")
    end

    it "raises error when choices is empty hash" do
      expect do
        OpenRosa::Fields::Select.new(:field, choices: {})
      end.to raise_error(ArgumentError, "choices cannot be empty")
    end

    it "raises error when choices is not an array or hash" do
      expect do
        OpenRosa::Fields::Select.new(:field, choices: "invalid")
      end.to raise_error(ArgumentError, "choices must be an Array or Hash")
    end
  end
end
