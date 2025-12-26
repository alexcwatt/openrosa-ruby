# frozen_string_literal: true

module OpenRosa
  module Fields
    # Boolean field for true/false values
    # Maps to XForms select1 element with true/false options
    # Data type: boolean (stored as "true" or "false" strings in XForms)
    class Boolean < Base
      attr_reader :appearance

      def initialize(name, options = {})
        super
        @appearance = options[:appearance]
      end
    end
  end
end
