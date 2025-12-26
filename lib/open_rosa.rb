# frozen_string_literal: true

require_relative "open_rosa/version"
require_relative "open_rosa/fields/base"
require_relative "open_rosa/fields/input"
require_relative "open_rosa/fields/select1"
require_relative "open_rosa/fields/select"
require_relative "open_rosa/fields/upload"
require_relative "open_rosa/fields/range"
require_relative "open_rosa/fields/trigger"
require_relative "open_rosa/fields/boolean"
require_relative "open_rosa/fields/group"
require_relative "open_rosa/fields/repeat"
require_relative "open_rosa/field_context"
require_relative "open_rosa/form_dsl"
require_relative "open_rosa/form"
require_relative "open_rosa/xform"
require_relative "open_rosa/form_list"
require_relative "open_rosa/submission"
require_relative "open_rosa/media_file"
require_relative "open_rosa/manifest"
require_relative "open_rosa/middleware"

module OpenRosa
  class Error < StandardError; end
  # Your code goes here...
end
