# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenRosa::XForm do
  describe "basic XML generation" do
    let(:simple_form) do
      Class.new(OpenRosa::Form) do
        form_id "simple_test"
        version "1.0"
        name "Simple Test Form"

        input :name, label: "Your Name", type: :string, required: true
        input :age, label: "Your Age", type: :int
      end
    end

    let(:generator) { OpenRosa::XForm.new(simple_form) }

    it "generates valid XML structure" do
      xml = generator.to_xml
      expect(xml).to include('<?xml version="1.0" encoding="UTF-8"?>')
      expect(xml).to include("<html")
      expect(xml).to include('xmlns="http://www.w3.org/2002/xforms"')
      expect(xml).to include('xmlns:h="http://www.w3.org/1999/xhtml"')
    end

    it "includes form metadata in head" do
      xml = generator.to_xml
      expect(xml).to include('<title xmlns="http://www.w3.org/1999/xhtml">Simple Test Form</title>')
      expect(xml).to include('id="simple_test"')
    end

    it "generates model with instance" do
      xml = generator.to_xml
      expect(xml).to include("<model>")
      expect(xml).to include("<instance>")
      expect(xml).to include('<simple_test id="simple_test" version="1.0">')
      expect(xml).to include("<name/>")
      expect(xml).to include("<age/>")
    end

    it "generates bindings for fields" do
      xml = generator.to_xml
      expect(xml).to include('<bind nodeset="/simple_test/name"')
      expect(xml).to include('type="string"')
      expect(xml).to include('required="true()"')
      expect(xml).to include('<bind nodeset="/simple_test/age"')
      expect(xml).to include('type="int"')
    end

    it "generates body with input controls" do
      xml = generator.to_xml
      expect(xml).to include('<body xmlns="http://www.w3.org/1999/xhtml">')
      expect(xml).to include('<input ref="/simple_test/name">')
      expect(xml).to include("<label>Your Name</label>")
      expect(xml).to include('<input ref="/simple_test/age">')
      expect(xml).to include("<label>Your Age</label>")
    end

    it "includes metadata fields" do
      xml = generator.to_xml
      expect(xml).to include("<meta>")
      expect(xml).to include("<instanceID/>")
    end
  end

  describe "select1 field generation" do
    let(:form_with_select) do
      Class.new(OpenRosa::Form) do
        form_id "select_test"
        version "1.0"

        select1 :color, label: "Favorite Color", choices: ["Red", "Green", "Blue"]
      end
    end

    let(:generator) { OpenRosa::XForm.new(form_with_select) }

    it "generates select1 control with items" do
      xml = generator.to_xml
      expect(xml).to include('<select1 ref="/select_test/color">')
      expect(xml).to include("<label>Favorite Color</label>")
      expect(xml).to include("<item>")
      expect(xml).to include("<value>Red</value>")
      expect(xml).to include("<value>Green</value>")
      expect(xml).to include("<value>Blue</value>")
    end
  end

  describe "group generation" do
    let(:form_with_group) do
      Class.new(OpenRosa::Form) do
        form_id "group_test"
        version "1.0"

        group :address, label: "Address" do
          input :street, label: "Street", type: :string
          input :city, label: "City", type: :string
        end
      end
    end

    let(:generator) { OpenRosa::XForm.new(form_with_group) }

    it "generates group in instance" do
      xml = generator.to_xml
      expect(xml).to include("<address>")
      expect(xml).to include("<street/>")
      expect(xml).to include("<city/>")
      expect(xml).to include("</address>")
    end

    it "generates group control in body" do
      xml = generator.to_xml
      expect(xml).to include('<group ref="/group_test/address">')
      expect(xml).to include("<label>Address</label>")
    end
  end

  describe "repeat generation" do
    let(:form_with_repeat) do
      Class.new(OpenRosa::Form) do
        form_id "repeat_test"
        version "1.0"

        repeat :items, label: "Items" do
          input :product, label: "Product", type: :string
          input :quantity, label: "Quantity", type: :int
        end
      end
    end

    let(:generator) { OpenRosa::XForm.new(form_with_repeat) }

    it "generates repeat in instance" do
      xml = generator.to_xml
      expect(xml).to include("<items>")
      expect(xml).to include("<product/>")
      expect(xml).to include("<quantity/>")
    end

    it "generates repeat control in body" do
      xml = generator.to_xml
      expect(xml).to include('<repeat nodeset="/repeat_test/items">')
      expect(xml).to include('<input ref="/repeat_test/items/product">')
    end
  end
end
