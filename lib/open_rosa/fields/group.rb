# frozen_string_literal: true

module OpenRosa
  module Fields
    # Group field for logical grouping of fields
    # Maps to XForms <group> element
    # Can contain nested fields and supports conditional display
    class Group < Base
      attr_reader :fields, :relevant, :appearance

      def initialize(name, options = {})
        super
        @fields = options.fetch(:fields, [])
        @relevant = options[:relevant]
        @appearance = options[:appearance]
      end
    end
  end
end
