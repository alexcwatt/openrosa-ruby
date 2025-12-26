# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenRosa::Fields::Select1 do
  describe "initialization" do
    it "inherits from Base" do
      field = OpenRosa::Fields::Select1.new(:satisfaction, choices: ["Good", "Bad"])
      expect(field).to be_a(OpenRosa::Fields::Base)
    end

    it "accepts choices option as array" do
      field = OpenRosa::Fields::Select1.new(:satisfaction, choices: ["Good", "Bad", "Neutral"])
      expect(field.choices).to eq(["Good", "Bad", "Neutral"])
    end

    it "accepts choices option as hash" do
      field = OpenRosa::Fields::Select1.new(
        :size,
        choices: { "S" => "Small", "M" => "Medium", "L" => "Large" }
      )
      expect(field.choices).to eq({ "S" => "Small", "M" => "Medium", "L" => "Large" })
    end

    it "accepts appearance option" do
      field = OpenRosa::Fields::Select1.new(:rating, choices: ["1", "2", "3"], appearance: "minimal")
      expect(field.appearance).to eq("minimal")
    end

    it "defaults appearance to nil" do
      field = OpenRosa::Fields::Select1.new(:rating, choices: ["1", "2", "3"])
      expect(field.appearance).to be_nil
    end
  end

  describe "with array choices" do
    let(:field) do
      OpenRosa::Fields::Select1.new(
        :satisfaction,
        label: "How satisfied are you?",
        choices: ["Very Satisfied", "Satisfied", "Neutral", "Unsatisfied"],
        required: true
      )
    end

    it "stores all attributes correctly" do
      expect(field.name).to eq(:satisfaction)
      expect(field.label).to eq("How satisfied are you?")
      expect(field.choices).to eq(["Very Satisfied", "Satisfied", "Neutral", "Unsatisfied"])
      expect(field.required).to eq(true)
    end
  end

  describe "with hash choices (value => label)" do
    let(:field) do
      OpenRosa::Fields::Select1.new(
        :shirt_size,
        label: "Select your size",
        choices: { "xs" => "Extra Small", "s" => "Small", "m" => "Medium", "l" => "Large" },
        appearance: "compact"
      )
    end

    it "stores all attributes correctly" do
      expect(field.name).to eq(:shirt_size)
      expect(field.label).to eq("Select your size")
      expect(field.choices).to eq({ "xs" => "Extra Small", "s" => "Small", "m" => "Medium", "l" => "Large" })
      expect(field.appearance).to eq("compact")
    end
  end

  describe "appearance options" do
    it "supports minimal appearance (dropdown)" do
      field = OpenRosa::Fields::Select1.new(:option, choices: ["A", "B"], appearance: "minimal")
      expect(field.appearance).to eq("minimal")
    end

    it "supports compact appearance" do
      field = OpenRosa::Fields::Select1.new(:option, choices: ["A", "B"], appearance: "compact")
      expect(field.appearance).to eq("compact")
    end

    it "supports quickcompact appearance" do
      field = OpenRosa::Fields::Select1.new(:option, choices: ["A", "B"], appearance: "quickcompact")
      expect(field.appearance).to eq("quickcompact")
    end
  end
end
