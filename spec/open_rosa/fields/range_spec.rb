# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenRosa::Fields::Range do
  describe "initialization" do
    it "inherits from Base" do
      field = OpenRosa::Fields::Range.new(:rating, start: 1, end: 10)
      expect(field).to be_a(OpenRosa::Fields::Base)
    end

    it "requires start option" do
      field = OpenRosa::Fields::Range.new(:rating, start: 1, end: 10)
      expect(field.start).to eq(1)
    end

    it "requires end option" do
      field = OpenRosa::Fields::Range.new(:rating, start: 1, end: 10)
      expect(field.end).to eq(10)
    end

    it "accepts step option" do
      field = OpenRosa::Fields::Range.new(:rating, start: 0, end: 100, step: 5)
      expect(field.step).to eq(5)
    end

    it "defaults step to 1" do
      field = OpenRosa::Fields::Range.new(:rating, start: 1, end: 10)
      expect(field.step).to eq(1)
    end

    it "accepts type option for decimal ranges" do
      field = OpenRosa::Fields::Range.new(:score, start: 0.0, end: 1.0, step: 0.1, type: :decimal)
      expect(field.type).to eq(:decimal)
    end

    it "defaults type to :int" do
      field = OpenRosa::Fields::Range.new(:rating, start: 1, end: 10)
      expect(field.type).to eq(:int)
    end
  end

  describe "integer range" do
    let(:field) do
      OpenRosa::Fields::Range.new(
        :satisfaction,
        label: "Rate your satisfaction",
        hint: "1 = Very Unsatisfied, 10 = Very Satisfied",
        start: 1,
        end: 10,
        step: 1,
        required: true
      )
    end

    it "stores all attributes correctly" do
      expect(field.name).to eq(:satisfaction)
      expect(field.label).to eq("Rate your satisfaction")
      expect(field.hint).to eq("1 = Very Unsatisfied, 10 = Very Satisfied")
      expect(field.start).to eq(1)
      expect(field.end).to eq(10)
      expect(field.step).to eq(1)
      expect(field.type).to eq(:int)
      expect(field.required).to eq(true)
    end
  end

  describe "decimal range" do
    let(:field) do
      OpenRosa::Fields::Range.new(
        :temperature,
        label: "Temperature (°C)",
        start: -10.0,
        end: 50.0,
        step: 0.5,
        type: :decimal
      )
    end

    it "stores all attributes correctly" do
      expect(field.name).to eq(:temperature)
      expect(field.label).to eq("Temperature (°C)")
      expect(field.start).to eq(-10.0)
      expect(field.end).to eq(50.0)
      expect(field.step).to eq(0.5)
      expect(field.type).to eq(:decimal)
    end
  end

  describe "validation" do
    it "raises error when start is missing" do
      expect do
        OpenRosa::Fields::Range.new(:rating, end: 10)
      end.to raise_error(ArgumentError, "start is required for Range field")
    end

    it "raises error when end is missing" do
      expect do
        OpenRosa::Fields::Range.new(:rating, start: 1)
      end.to raise_error(ArgumentError, "end is required for Range field")
    end

    it "raises error when start is greater than or equal to end" do
      expect do
        OpenRosa::Fields::Range.new(:rating, start: 10, end: 5)
      end.to raise_error(ArgumentError, "start must be less than end")
    end

    it "raises error when start equals end" do
      expect do
        OpenRosa::Fields::Range.new(:rating, start: 5, end: 5)
      end.to raise_error(ArgumentError, "start must be less than end")
    end

    it "raises error when step is zero" do
      expect do
        OpenRosa::Fields::Range.new(:rating, start: 1, end: 10, step: 0)
      end.to raise_error(ArgumentError, "step must be greater than 0")
    end

    it "raises error when step is negative" do
      expect do
        OpenRosa::Fields::Range.new(:rating, start: 1, end: 10, step: -1)
      end.to raise_error(ArgumentError, "step must be greater than 0")
    end

    it "raises error when type is invalid" do
      expect do
        OpenRosa::Fields::Range.new(:rating, start: 1, end: 10, type: :string)
      end.to raise_error(ArgumentError, "type must be :int or :decimal")
    end

    it "allows valid int type" do
      expect do
        OpenRosa::Fields::Range.new(:rating, start: 1, end: 10, type: :int)
      end.not_to raise_error
    end

    it "allows valid decimal type" do
      expect do
        OpenRosa::Fields::Range.new(:rating, start: 1.0, end: 10.0, type: :decimal)
      end.not_to raise_error
    end
  end
end
