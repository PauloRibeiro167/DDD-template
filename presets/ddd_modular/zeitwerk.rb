# frozen_string_literal: true

gsub_file "config/application.rb", 'config.autoload_lib(ignore: %w[assets tasks])', 'config.autoload_lib(ignore: %w[assets tasks generators])'

initializer "zeitwerk_ddd_roots.rb", <<~RUBY
  domains_root = Rails.root.join("app/domains")
  http_controllers_root = Rails.root.join("app/interfaces/http/controllers")
  http_forms_root = Rails.root.join("app/interfaces/http/forms")
  http_presenters_root = Rails.root.join("app/interfaces/http/presenters")

  Rails.autoloaders.main.ignore(domains_root)
  Rails.autoloaders.main.ignore(http_controllers_root)
  Rails.autoloaders.main.ignore(http_forms_root)
  Rails.autoloaders.main.ignore(http_presenters_root)

  Rails.autoloaders.main.push_dir(domains_root)
  Rails.autoloaders.main.push_dir(http_controllers_root)
  Rails.autoloaders.main.push_dir(http_forms_root)
  Rails.autoloaders.main.push_dir(http_presenters_root)
RUBY
