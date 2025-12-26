# frozen_string_literal: true

require "nokogiri"

module OpenRosa
  # Generates XForm XML from Form definitions
  # rubocop:disable Metrics/ClassLength
  class XForm
    XFORMS_NS = "http://www.w3.org/2002/xforms"
    XHTML_NS = "http://www.w3.org/1999/xhtml"

    def initialize(form_class)
      @form_class = form_class
      @form_id = form_class.form_id
      @version = form_class.version
      @name = form_class.name || form_class.form_id
      @fields = form_class.fields
    end

    def to_xml
      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml.html(xform_namespaces) do
          generate_head(xml)
          generate_body(xml)
        end
      end

      builder.to_xml
    end

    def xform_namespaces
      {
        "xmlns" => XFORMS_NS,
        "xmlns:h" => XHTML_NS,
        "xmlns:ev" => "http://www.w3.org/2001/xml-events",
        "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
        "xmlns:jr" => "http://openrosa.org/javarosa"
      }
    end

    private

    def generate_head(xml)
      xml.head do
        xml.title(@name, xmlns: XHTML_NS)
        xml.model do
          generate_instance(xml)
          generate_bindings(xml)
        end
      end
    end

    def generate_instance(xml)
      xml.instance do
        xml.send(@form_id.to_sym, id: @form_id, version: @version) do
          generate_instance_fields(xml, @fields)
          generate_metadata(xml)
        end
      end
    end

    def generate_instance_fields(xml, fields, _path_prefix = nil)
      fields.each do |field|
        case field
        when Fields::Group, Fields::Repeat
          xml.send(field.name.to_sym) do
            generate_instance_fields(xml, field.fields, field.name)
          end
        else
          xml.send(field.name.to_sym)
        end
      end
    end

    def generate_metadata(xml)
      xml.meta do
        xml.instanceID
      end
    end

    def generate_bindings(xml)
      generate_field_bindings(xml, @fields, "/#{@form_id}")
    end

    def generate_field_bindings(xml, fields, path_prefix)
      fields.each do |field|
        nodeset = "#{path_prefix}/#{field.name}"
        generate_binding_for_field(xml, field, nodeset)
      end
    end

    def generate_binding_for_field(xml, field, nodeset)
      case field
      when Fields::Group
        xml.bind(nodeset: nodeset, relevant: field.relevant) if field.relevant
        generate_field_bindings(xml, field.fields, nodeset)
      when Fields::Repeat
        generate_field_bindings(xml, field.fields, nodeset)
      else
        xml.bind(build_bind_attrs(field, nodeset))
      end
    end

    def build_bind_attrs(field, nodeset)
      attrs = { nodeset: nodeset, type: binding_type(field) }
      attrs[:required] = "true()" if field.required
      attrs[:constraint] = field.constraint if field.respond_to?(:constraint) && field.constraint
      attrs
    end

    def binding_type(field)
      case field
      when Fields::Input, Fields::Range
        field.type.to_s
      when Fields::Upload
        "binary"
      else
        "string"
      end
    end

    def generate_body(xml)
      xml.body(xmlns: XHTML_NS) do
        generate_controls(xml, @fields, "/#{@form_id}")
      end
    end

    def generate_controls(xml, fields, path_prefix)
      fields.each do |field|
        ref = "#{path_prefix}/#{field.name}"
        generate_control_for_field(xml, field, ref)
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
    def generate_control_for_field(xml, field, ref)
      case field
      when Fields::Input then generate_input_control(xml, field, ref)
      when Fields::Select1 then generate_select1_control(xml, field, ref)
      when Fields::Select then generate_select_control(xml, field, ref)
      when Fields::Boolean then generate_boolean_control(xml, field, ref)
      when Fields::Upload then generate_upload_control(xml, field, ref)
      when Fields::Range then generate_range_control(xml, field, ref)
      when Fields::Trigger then generate_trigger_control(xml, field, ref)
      when Fields::Group then generate_group_control(xml, field, ref)
      when Fields::Repeat then generate_repeat_control(xml, field, ref)
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

    def generate_input_control(xml, field, ref)
      xml.input(ref: ref) do
        add_label_and_hint(xml, field)
      end
    end

    def generate_select1_control(xml, field, ref)
      xml.select1(ref: ref) do
        add_label_and_hint(xml, field)
        generate_choices(xml, field.choices)
      end
    end

    def generate_select_control(xml, field, ref)
      xml.select(ref: ref) do
        add_label_and_hint(xml, field)
        generate_choices(xml, field.choices)
      end
    end

    def generate_boolean_control(xml, field, ref)
      xml.select1(ref: ref) do
        add_label_and_hint(xml, field)
        generate_boolean_choices(xml)
      end
    end

    def generate_boolean_choices(xml)
      xml.item do
        xml.label "Yes"
        xml.value "true"
      end
      xml.item do
        xml.label "No"
        xml.value "false"
      end
    end

    def generate_upload_control(xml, field, ref)
      xml.upload(ref: ref, mediatype: field.mediatype) do
        add_label_and_hint(xml, field)
      end
    end

    def generate_range_control(xml, field, ref)
      xml.range(ref: ref, start: field.start, end: field.end, step: field.step) do
        add_label_and_hint(xml, field)
      end
    end

    def generate_trigger_control(xml, field, ref)
      xml.trigger(ref: ref) do
        add_label_and_hint(xml, field)
      end
    end

    def generate_group_control(xml, field, ref)
      xml.group(ref: ref) do
        xml.label field.label if field.label
        generate_controls(xml, field.fields, ref)
      end
    end

    def generate_repeat_control(xml, field, ref)
      xml.repeat(nodeset: ref) do
        xml.label field.label if field.label
        generate_controls(xml, field.fields, ref)
      end
    end

    def add_label_and_hint(xml, field)
      xml.label field.label if field.label
      xml.hint field.hint if field.hint
    end

    def generate_choices(xml, choices)
      generate_array_choices(xml, choices) if choices.is_a?(Array)
      generate_hash_choices(xml, choices) if choices.is_a?(Hash)
    end

    def generate_array_choices(xml, choices)
      choices.each do |choice|
        xml.item do
          xml.label choice
          xml.value choice
        end
      end
    end

    def generate_hash_choices(xml, choices)
      choices.each do |label, value|
        xml.item do
          xml.label label
          xml.value value
        end
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
