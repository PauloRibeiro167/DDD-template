# frozen_string_literal: true

initializer "zeitwerk_api_lite.rb", <<~RUBY
  domains_root = Rails.root.join("app/domains")
  http_controllers_root = Rails.root.join("app/interfaces/http/controllers")
  http_serializers_root = Rails.root.join("app/interfaces/http/serializers")

  Rails.autoloaders.main.ignore(domains_root)
  Rails.autoloaders.main.ignore(http_controllers_root)
  Rails.autoloaders.main.ignore(http_serializers_root)

  Rails.autoloaders.main.push_dir(domains_root)
  Rails.autoloaders.main.push_dir(http_controllers_root)
  Rails.autoloaders.main.push_dir(http_serializers_root)
RUBY
