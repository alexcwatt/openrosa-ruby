# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenRosa::Fields::Repeat do
  describe "initialization" do
    it "inherits from Base" do
      repeat = OpenRosa::Fields::Repeat.new(:items)
      expect(repeat).to be_a(OpenRosa::Fields::Base)
    end

    it "accepts fields option as array" do
      product_field = OpenRosa::Fields::Input.new(:product, type: :string)
      qty_field = OpenRosa::Fields::Input.new(:quantity, type: :int)

      repeat = OpenRosa::Fields::Repeat.new(:items, fields: [product_field, qty_field])
      expect(repeat.fields).to eq([product_field, qty_field])
    end

    it "defaults fields to empty array" do
      repeat = OpenRosa::Fields::Repeat.new(:entries)
      expect(repeat.fields).to eq([])
    end

    it "accepts count option for fixed repeats" do
      repeat = OpenRosa::Fields::Repeat.new(:items, count: 3)
      expect(repeat.count).to eq(3)
    end

    it "defaults count to nil for dynamic repeats" do
      repeat = OpenRosa::Fields::Repeat.new(:items)
      expect(repeat.count).to be_nil
    end

    it "accepts appearance option" do
      repeat = OpenRosa::Fields::Repeat.new(:items, appearance: "compact")
      expect(repeat.appearance).to eq("compact")
    end

    it "accepts relevant option for conditional repeats" do
      repeat = OpenRosa::Fields::Repeat.new(:items, relevant: "${has_items} = 'yes'")
      expect(repeat.relevant).to eq("${has_items} = 'yes'")
    end
  end

  describe "dynamic repeat (no fixed count)" do
    let(:product_field) { OpenRosa::Fields::Input.new(:product_name, label: "Product", type: :string) }
    let(:quantity_field) { OpenRosa::Fields::Input.new(:quantity, label: "Quantity", type: :int) }
    let(:price_field) { OpenRosa::Fields::Input.new(:price, label: "Price", type: :decimal) }

    let(:repeat) do
      OpenRosa::Fields::Repeat.new(
        :order_items,
        label: "Order Items",
        hint: "Add items to your order",
        fields: [product_field, quantity_field, price_field]
      )
    end

    it "stores all attributes correctly" do
      expect(repeat.name).to eq(:order_items)
      expect(repeat.label).to eq("Order Items")
      expect(repeat.hint).to eq("Add items to your order")
      expect(repeat.fields).to eq([product_field, quantity_field, price_field])
      expect(repeat.count).to be_nil
    end
  end

  describe "fixed count repeat" do
    let(:name_field) { OpenRosa::Fields::Input.new(:member_name, label: "Name", type: :string) }

    let(:repeat) do
      OpenRosa::Fields::Repeat.new(
        :household_members,
        label: "Household Members",
        count: 5,
        fields: [name_field]
      )
    end

    it "stores count correctly" do
      expect(repeat.name).to eq(:household_members)
      expect(repeat.label).to eq("Household Members")
      expect(repeat.count).to eq(5)
      expect(repeat.fields).to eq([name_field])
    end
  end

  describe "conditional repeat" do
    let(:repeat) do
      OpenRosa::Fields::Repeat.new(
        :additional_notes,
        label: "Additional Notes",
        relevant: "${add_notes} = 'yes'",
        fields: []
      )
    end

    it "stores relevant condition" do
      expect(repeat.relevant).to eq("${add_notes} = 'yes'")
    end
  end

  describe "repeat with appearance" do
    let(:repeat) do
      OpenRosa::Fields::Repeat.new(
        :entries,
        label: "Entries",
        appearance: "minimal",
        fields: []
      )
    end

    it "stores appearance correctly" do
      expect(repeat.appearance).to eq("minimal")
    end
  end
end
