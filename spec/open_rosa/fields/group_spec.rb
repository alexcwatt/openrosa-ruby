# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenRosa::Fields::Group do
  describe "initialization" do
    it "inherits from Base" do
      group = OpenRosa::Fields::Group.new(:personal_info)
      expect(group).to be_a(OpenRosa::Fields::Base)
    end

    it "accepts fields option as array" do
      name_field = OpenRosa::Fields::Input.new(:name, type: :string)
      age_field = OpenRosa::Fields::Input.new(:age, type: :int)

      group = OpenRosa::Fields::Group.new(:personal_info, fields: [name_field, age_field])
      expect(group.fields).to eq([name_field, age_field])
    end

    it "defaults fields to empty array" do
      group = OpenRosa::Fields::Group.new(:info)
      expect(group.fields).to eq([])
    end

    it "accepts relevant option for conditional display" do
      group = OpenRosa::Fields::Group.new(:extra_info, relevant: "${show_extra} = 'yes'")
      expect(group.relevant).to eq("${show_extra} = 'yes'")
    end

    it "defaults relevant to nil" do
      group = OpenRosa::Fields::Group.new(:info)
      expect(group.relevant).to be_nil
    end

    it "accepts appearance option" do
      group = OpenRosa::Fields::Group.new(:section, appearance: "field-list")
      expect(group.appearance).to eq("field-list")
    end
  end

  describe "simple group" do
    let(:name_field) { OpenRosa::Fields::Input.new(:name, label: "Name", type: :string) }
    let(:age_field) { OpenRosa::Fields::Input.new(:age, label: "Age", type: :int) }

    let(:group) do
      OpenRosa::Fields::Group.new(
        :personal_info,
        label: "Personal Information",
        hint: "Please provide your personal details",
        fields: [name_field, age_field]
      )
    end

    it "stores all attributes correctly" do
      expect(group.name).to eq(:personal_info)
      expect(group.label).to eq("Personal Information")
      expect(group.hint).to eq("Please provide your personal details")
      expect(group.fields).to eq([name_field, age_field])
    end
  end

  describe "conditional group" do
    let(:group) do
      OpenRosa::Fields::Group.new(
        :shipping_address,
        label: "Shipping Address",
        relevant: "${different_shipping} = 'yes'",
        fields: []
      )
    end

    it "stores relevant condition" do
      expect(group.name).to eq(:shipping_address)
      expect(group.label).to eq("Shipping Address")
      expect(group.relevant).to eq("${different_shipping} = 'yes'")
    end
  end

  describe "field-list appearance" do
    let(:group) do
      OpenRosa::Fields::Group.new(
        :demographics,
        label: "Demographics",
        appearance: "field-list",
        fields: []
      )
    end

    it "stores appearance correctly" do
      expect(group.appearance).to eq("field-list")
    end
  end
end
