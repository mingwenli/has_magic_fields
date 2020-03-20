require "has_magic_fields/version"
require "has_magic_fields/extend"

module HasMagicFields
  class Engine < ::Rails::Engine
    paths = Dir[File.dirname(__FILE__), '/app/models/**/']
    config.eager_load_paths += paths
  end
end
