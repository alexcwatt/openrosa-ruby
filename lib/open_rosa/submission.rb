# frozen_string_literal: true

require "rack"
require "nokogiri"

module OpenRosa
  # Represents a parsed OpenRosa form submission
  #
  # Handles parsing of multipart MIME submissions containing:
  # - XML submission file (required, named "xml_submission_file")
  # - Media attachments (optional, images/audio/video)
  #
  # Per OpenRosa spec:
  # - POST to /submission with multipart/form-data
  # - XML part must be named "xml_submission_file"
  # - Other parts are treated as media attachments
  class Submission # rubocop:disable Metrics/ClassLength
    attr_reader :form_id, :instance_id, :data, :attachments, :metadata, :raw_xml

    class ParseError < StandardError; end

    # rubocop:disable Metrics/ParameterLists
    def initialize(form_id:, instance_id:, data:, raw_xml:, attachments: [], metadata: {})
      # rubocop:enable Metrics/ParameterLists
      @form_id = form_id
      @instance_id = instance_id
      @data = data
      @attachments = attachments
      @metadata = metadata
      @raw_xml = raw_xml
    end

    class << self
      # Parse a Rack request into a Submission object
      #
      # @param rack_request [Rack::Request] The incoming request
      # @return [Submission] Parsed submission
      # @raise [ParseError] If submission is invalid
      def parse(rack_request)
        validate_request!(rack_request)
        raw_xml = extract_raw_xml(rack_request)
        doc = parse_xml(raw_xml)

        build_submission(doc, rack_request, raw_xml)
      end

      private

      def validate_request!(rack_request)
        raise ParseError, "Request must be POST" unless rack_request.post?
        raise ParseError, "Content-Type must be multipart/form-data" unless multipart?(rack_request)
      end

      def extract_raw_xml(rack_request)
        xml_param = rack_request.params["xml_submission_file"]
        raise ParseError, "Missing xml_submission_file parameter" unless xml_param

        raw_xml = read_xml_param(xml_param)
        raise ParseError, "Empty xml_submission_file" if raw_xml.nil? || raw_xml.empty?

        raw_xml
      end

      def read_xml_param(xml_param)
        if xml_param.respond_to?(:read)
          xml_param.read
        elsif xml_param.is_a?(Hash) && xml_param[:tempfile]
          xml_param[:tempfile].read
        else
          xml_param.to_s
        end
      end

      def build_submission(doc, rack_request, raw_xml)
        new(
          form_id: extract_form_id(doc),
          instance_id: extract_instance_id(doc),
          data: extract_data(doc),
          attachments: extract_attachments(rack_request),
          metadata: extract_metadata(doc),
          raw_xml: raw_xml
        )
      end

      def multipart?(request)
        content_type = request.content_type
        content_type&.start_with?("multipart/form-data")
      end

      def parse_xml(raw_xml)
        Nokogiri::XML(raw_xml) do |config|
          config.strict.nonet
        end
      rescue Nokogiri::XML::SyntaxError => e
        raise ParseError, "Invalid XML: #{e.message}"
      end

      def extract_form_id(doc)
        # The root element's name or id attribute is the form ID
        root = doc.root
        raise ParseError, "XML document has no root element" unless root

        # Try id attribute first, then use element name
        root["id"] || root.name
      end

      def extract_instance_id(doc)
        # Look for meta/instanceID element
        instance_id_node = doc.at_xpath("//meta/instanceID") ||
                           doc.at_xpath("//*[local-name()='instanceID']")

        instance_id_node&.text&.strip
      end

      def extract_data(doc)
        root = doc.root
        data = {}

        # Recursively extract all leaf nodes as data
        extract_node_data(root, data)

        data
      end

      def extract_node_data(node, data, prefix = nil)
        node.element_children.each do |child|
          # Skip meta elements
          next if child.name == "meta"

          field_name = prefix ? "#{prefix}/#{child.name}" : child.name

          if child.element_children.empty?
            # Leaf node - extract value
            data[field_name] = child.text.strip
          else
            # Has children - recurse (for groups/repeats)
            extract_node_data(child, data, field_name)
          end
        end
      end

      def extract_metadata(doc)
        metadata = {}

        # Extract common metadata fields
        meta_node = doc.at_xpath("//meta") || doc.at_xpath("//*[local-name()='meta']")
        return metadata unless meta_node

        ["instanceID", "timeStart", "timeEnd", "deviceID", "userID"].each do |field|
          node = meta_node.at_xpath(field) || meta_node.at_xpath("*[local-name()='#{field}']")
          metadata[field.to_sym] = node.text.strip if node
        end

        metadata
      end

      def extract_attachments(rack_request)
        rack_request.params.filter_map do |name, value|
          next if name == "xml_submission_file"
          next unless value.is_a?(Hash) && value[:tempfile]

          Attachment.new(
            filename: value[:filename],
            content_type: value[:type] || "application/octet-stream",
            size: value[:tempfile].size,
            tempfile: value[:tempfile]
          )
        end
      end
    end

    # Represents an uploaded file attachment
    class Attachment
      attr_reader :filename, :content_type, :size, :tempfile

      def initialize(filename:, content_type:, size:, tempfile:)
        @filename = filename
        @content_type = content_type
        @size = size
        @tempfile = tempfile
      end

      # Read the file contents
      def read
        tempfile.rewind
        tempfile.read
      end

      # Get the file path (useful for moving/copying)
      def path
        tempfile.path
      end
    end
  end
end
