# frozen_string_literal: true

module OpenRosa
  module Fields
    # Upload field for file/media uploads
    # Maps to XForms <upload> element
    # Data type: binary
    class Upload < Base
      attr_reader :mediatype, :max_pixels

      def initialize(name, options = {})
        super
        @mediatype = options[:mediatype]
        @max_pixels = options[:max_pixels]
      end
    end
  end
end
