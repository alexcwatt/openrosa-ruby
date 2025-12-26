# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenRosa::Fields::Trigger do
  describe "initialization" do
    it "inherits from Base" do
      field = OpenRosa::Fields::Trigger.new(:acknowledge)
      expect(field).to be_a(OpenRosa::Fields::Base)
    end

    it "accepts appearance option" do
      field = OpenRosa::Fields::Trigger.new(:confirm, appearance: "minimal")
      expect(field.appearance).to eq("minimal")
    end

    it "defaults appearance to nil" do
      field = OpenRosa::Fields::Trigger.new(:acknowledge)
      expect(field.appearance).to be_nil
    end
  end

  describe "confirmation trigger" do
    let(:field) do
      OpenRosa::Fields::Trigger.new(
        :terms_accepted,
        label: "I accept the terms and conditions",
        hint: "You must accept to continue",
        required: true
      )
    end

    it "stores all attributes correctly" do
      expect(field.name).to eq(:terms_accepted)
      expect(field.label).to eq("I accept the terms and conditions")
      expect(field.hint).to eq("You must accept to continue")
      expect(field.required).to eq(true)
    end
  end

  describe "acknowledgement trigger" do
    let(:field) do
      OpenRosa::Fields::Trigger.new(
        :acknowledge_instructions,
        label: "I have read and understood the instructions",
        appearance: "minimal"
      )
    end

    it "stores all attributes correctly" do
      expect(field.name).to eq(:acknowledge_instructions)
      expect(field.label).to eq("I have read and understood the instructions")
      expect(field.appearance).to eq("minimal")
      expect(field.required).to eq(false)
    end
  end
end
