# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenRosa::Fields::Input do
  describe "initialization" do
    it "inherits from Base" do
      field = OpenRosa::Fields::Input.new(:name)
      expect(field).to be_a(OpenRosa::Fields::Base)
    end

    it "accepts type option" do
      field = OpenRosa::Fields::Input.new(:age, type: :int)
      expect(field.type).to eq(:int)
    end

    it "defaults type to :string" do
      field = OpenRosa::Fields::Input.new(:name)
      expect(field.type).to eq(:string)
    end

    it "accepts constraint option" do
      field = OpenRosa::Fields::Input.new(:age, constraint: ". >= 18")
      expect(field.constraint).to eq(". >= 18")
    end

    it "accepts constraint_message option" do
      field = OpenRosa::Fields::Input.new(:age, constraint_message: "Must be 18 or older")
      expect(field.constraint_message).to eq("Must be 18 or older")
    end
  end

  describe "data types" do
    it "supports string type" do
      field = OpenRosa::Fields::Input.new(:name, type: :string)
      expect(field.type).to eq(:string)
    end

    it "supports int type" do
      field = OpenRosa::Fields::Input.new(:age, type: :int)
      expect(field.type).to eq(:int)
    end

    it "supports decimal type" do
      field = OpenRosa::Fields::Input.new(:price, type: :decimal)
      expect(field.type).to eq(:decimal)
    end

    it "supports date type" do
      field = OpenRosa::Fields::Input.new(:birth_date, type: :date)
      expect(field.type).to eq(:date)
    end

    it "supports time type" do
      field = OpenRosa::Fields::Input.new(:appointment_time, type: :time)
      expect(field.type).to eq(:time)
    end

    it "supports dateTime type" do
      field = OpenRosa::Fields::Input.new(:created_at, type: :dateTime)
      expect(field.type).to eq(:dateTime)
    end

    it "supports geopoint type" do
      field = OpenRosa::Fields::Input.new(:location, type: :geopoint)
      expect(field.type).to eq(:geopoint)
    end

    it "supports barcode type" do
      field = OpenRosa::Fields::Input.new(:product_code, type: :barcode)
      expect(field.type).to eq(:barcode)
    end
  end

  describe "full example" do
    let(:field) do
      OpenRosa::Fields::Input.new(
        :age,
        label: "Your Age",
        hint: "Must be 18 or older",
        type: :int,
        required: true,
        constraint: ". >= 18",
        constraint_message: "You must be at least 18 years old"
      )
    end

    it "stores all attributes correctly" do
      expect(field.name).to eq(:age)
      expect(field.label).to eq("Your Age")
      expect(field.hint).to eq("Must be 18 or older")
      expect(field.type).to eq(:int)
      expect(field.required).to eq(true)
      expect(field.constraint).to eq(". >= 18")
      expect(field.constraint_message).to eq("You must be at least 18 years old")
    end
  end

  describe "validation" do
    it "raises error for invalid type" do
      expect do
        OpenRosa::Fields::Input.new(:field, type: :invalid)
      end.to raise_error(ArgumentError, /type must be one of/)
    end

    it "allows all valid types" do
      valid_types = %i[string int decimal date time dateTime geopoint geotrace geoshape barcode binary intent]

      valid_types.each do |type|
        expect do
          OpenRosa::Fields::Input.new(:field, type: type)
        end.not_to raise_error
      end
    end
  end

  describe "constraint validation" do
    it "allows simple regex constraints" do
      expect do
        OpenRosa::Fields::Input.new(:email, constraint: "regex(., '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+[.][a-zA-Z]{2,}')")
      end.not_to raise_error
    end

    it "allows non-regex constraints" do
      expect do
        OpenRosa::Fields::Input.new(:age, type: :int, constraint: ". >= 18 and . <= 120")
      end.not_to raise_error
    end

    it "allows Java-style regex features since JavaRosa uses java.util.regex" do
      expect do
        OpenRosa::Fields::Input.new(:email, constraint: "regex(., '(?:[a-z]+)@[a-z]+[.][a-z]+')")
      end.not_to raise_error
    end

    it "rejects invalid regex patterns" do
      expect do
        OpenRosa::Fields::Input.new(:field, constraint: "regex(., '[unclosed')")
      end.to raise_error(ArgumentError, /not a valid regular expression/)
    end

    it "rejects unbalanced parentheses in regex" do
      expect do
        OpenRosa::Fields::Input.new(:field, constraint: "regex(., '(unclosed')")
      end.to raise_error(ArgumentError, /not a valid regular expression/)
    end

    it "rejects regex patterns containing unescaped single quotes" do
      # A single quote inside a single-quoted XPath string breaks the XPath parser
      expect do
        OpenRosa::Fields::Input.new(:field, constraint: "regex(., 'it's broken')")
      end.to raise_error(ArgumentError, /unquoted pattern/)
    end

    it "allows constraints without regex" do
      expect do
        OpenRosa::Fields::Input.new(:age, type: :int, constraint: ". > 0")
      end.not_to raise_error
    end

    it "allows multiple regex calls in one constraint" do
      expect do
        OpenRosa::Fields::Input.new(:field, constraint: "regex(., '[a-z]+') and regex(., '.*@.*')")
      end.not_to raise_error
    end

    it "validates double-quoted regex patterns" do
      expect do
        OpenRosa::Fields::Input.new(:email, constraint: 'regex(., "[a-z]+@[a-z]+[.][a-z]+")')
      end.not_to raise_error
    end

    it "rejects invalid double-quoted regex patterns" do
      expect do
        OpenRosa::Fields::Input.new(:field, constraint: 'regex(., "[unclosed")')
      end.to raise_error(ArgumentError, /not a valid regular expression/)
    end

    it "allows empty regex pattern" do
      expect do
        OpenRosa::Fields::Input.new(:field, constraint: "regex(., '')")
      end.not_to raise_error
    end
  end
end
