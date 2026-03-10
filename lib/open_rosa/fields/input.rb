# frozen_string_literal: true

module OpenRosa
  module Fields
    # Input field for text, numbers, dates, and other basic input types
    class Input < Base
      attr_reader :type, :constraint, :constraint_message

      VALID_TYPES = %i[
        string int decimal date time dateTime
        geopoint geotrace geoshape barcode binary intent
      ].freeze

      # Matches regex() calls with single- or double-quoted patterns
      REGEX_CALL = /regex\s*\(/
      REGEX_WITH_PATTERN = /regex\s*\(\s*[^,]+,\s*(?:'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)")\s*\)/

      def initialize(name, options = {})
        super
        @type = options.fetch(:type, :string)
        @constraint = options[:constraint]
        @constraint_message = options[:constraint_message]

        validate!
      end

      private

      def validate!
        validate_type!
        validate_constraint! if @constraint
      end

      def validate_type!
        return if VALID_TYPES.include?(@type)

        raise ArgumentError, "type must be one of: #{VALID_TYPES.join(", ")}"
      end

      def validate_constraint!
        # Extract and validate regex patterns from expressions like: regex(., 'pattern')
        # Patterns are inside quotes in the XPath expression — an unescaped quote
        # breaks the XPath parser on the device. We also verify patterns compile.
        # Ruby's Oniguruma engine is a superset of Java's java.util.regex.Pattern,
        # so a pattern that fails here will also fail on the device.
        matched_patterns = @constraint.scan(REGEX_WITH_PATTERN)
        matched_patterns.each do |single_quoted, double_quoted|
          validate_regex_pattern!(single_quoted || double_quoted)
        end

        # If there are more regex() calls than we could parse, a quote is broken
        regex_call_count = @constraint.scan(REGEX_CALL).length
        return unless regex_call_count > matched_patterns.length

        raise ArgumentError,
              "constraint for '#{name}' contains a regex() with an invalid or " \
              "unquoted pattern — check for unescaped quotes"
      end

      def validate_regex_pattern!(pattern)
        Regexp.new(pattern)
      rescue RegexpError => e
        raise ArgumentError,
              "constraint regex for '#{name}' is not a valid regular expression: #{e.message}"
      end
    end
  end
end
