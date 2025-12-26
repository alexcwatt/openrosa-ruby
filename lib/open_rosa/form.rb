# frozen_string_literal: true

module OpenRosa
  # Base class for defining OpenRosa forms with a clean DSL
  class Form
    class << self
      include FormDSL

      def form_id(id = nil)
        if id
          @form_id = id
        else
          @form_id
        end
      end

      def version(ver = nil)
        if ver
          @version = ver
        else
          @version
        end
      end

      def name(form_name = nil)
        if form_name
          @name = form_name
        else
          @name
        end
      end

      def description_text(text = nil)
        if text
          @description_text = text
        else
          @description_text
        end
      end

      def description_url(url = nil)
        if url
          @description_url = url
        else
          @description_url
        end
      end

      def download_url(url = nil)
        if url
          @download_url = url
        else
          @download_url
        end
      end

      def manifest_url(url = nil)
        if url
          @manifest_url = url
        else
          @manifest_url
        end
      end

      # Calculates MD5 hash of the form's XForm XML content
      # Returns format: "md5:abc123..."
      def form_hash
        require "digest"
        xml = to_xml
        hash = Digest::MD5.hexdigest(xml)
        "md5:#{hash}"
      end

      # Generates XForm XML from the form definition
      # Returns the complete XForm XML as a string
      def to_xml
        XForm.new(self).to_xml
      end

      # Define a handler for form submissions
      #
      # @yield [submission] The parsed submission
      # @yieldparam submission [Submission] The submission object
      # @yieldreturn [String, nil] Optional success message
      #
      # Example:
      #   class MyForm < OpenRosa::Form
      #     on_submit do |submission|
      #       MyModel.create!(data: submission.data)
      #       "Thanks for submitting!"
      #     end
      #   end
      def on_submit(&block)
        @submission_handler = block
      end

      # Handle a submission (called by middleware)
      #
      # @param submission [Submission] The parsed submission
      # @return [String, nil] Success message or nil
      def handle_submission(submission)
        @submission_handler&.call(submission)
      end
    end

    def form_id
      self.class.form_id
    end

    def version
      self.class.version
    end

    def name
      self.class.name
    end

    def description_text
      self.class.description_text
    end

    def description_url
      self.class.description_url
    end

    def download_url
      self.class.download_url
    end

    def manifest_url
      self.class.manifest_url
    end

    def form_hash
      self.class.form_hash
    end

    def fields
      self.class.fields
    end

    def to_xml
      self.class.to_xml
    end
  end
end
