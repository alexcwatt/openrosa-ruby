# frozen_string_literal: true

require "nokogiri"

module OpenRosa
  # Generates OpenRosa Form List API XML responses
  # Spec: https://docs.getodk.org/openrosa-form-list/
  class FormList
    XFORMS_LIST_NS = "http://openrosa.org/xforms/xformsList"

    def initialize(forms, options = {})
      @forms = forms
      @verbose = options.fetch(:verbose, false)
      @form_id = options[:form_id]
      @base_url = options[:base_url]
      @mount_path = options[:mount_path] || "/openrosa"
    end

    def to_xml
      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml.xforms(xmlns: XFORMS_LIST_NS) do
          filtered_forms.each do |form_class|
            generate_xform_entry(xml, form_class)
          end
        end
      end

      builder.to_xml
    end

    private

    def filtered_forms
      return @forms unless @form_id

      @forms.select { |form| form.form_id == @form_id }
    end

    def generate_xform_entry(xml, form_class)
      xml.xform do
        add_required_fields(xml, form_class)
        add_verbose_fields(xml, form_class) if @verbose
        add_optional_fields(xml, form_class)
      end
    end

    def add_required_fields(xml, form_class)
      xml.formID form_class.form_id
      xml.name form_class.name if form_class.name
      xml.version form_class.version if form_class.version
      xml.hash_ form_class.form_hash
      url = download_url_for(form_class)
      xml.downloadUrl url if url
    end

    def download_url_for(form_class)
      # Use explicit download_url if set on the form
      return form_class.download_url if form_class.download_url

      # Auto-generate from base_url if configured
      unless @base_url
        raise ArgumentError,
              "Form '#{form_class.form_id}' has no download_url. " \
              "Either set download_url on the form or configure base_url in the middleware."
      end

      "#{@base_url}#{@mount_path}/forms/#{form_class.form_id}"
    end

    def add_verbose_fields(xml, form_class)
      xml.descriptionText form_class.description_text if form_class.description_text
      xml.descriptionUrl form_class.description_url if form_class.description_url
    end

    def add_optional_fields(xml, form_class)
      url = manifest_url_for(form_class)
      xml.manifestUrl url if url
    end

    def manifest_url_for(form_class)
      # Use explicit manifest_url if set on the form
      return form_class.manifest_url if form_class.manifest_url

      # Auto-generate from base_url if form has a manifest defined
      return nil unless @base_url
      return nil unless form_has_manifest?(form_class)

      "#{@base_url}#{@mount_path}/manifests/#{form_class.form_id}"
    end

    def form_has_manifest?(form_class)
      # Handle both class and instance (middleware passes instances)
      klass = form_class.is_a?(Class) ? form_class : form_class.class
      klass.respond_to?(:manifest) && klass.manifest
    end
  end
end
