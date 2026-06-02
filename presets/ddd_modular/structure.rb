# frozen_string_literal: true

directories_to_remove = [
  "app/controllers",
  "app/helpers",
  "app/mailers",
  "app/models/concerns"
]

base_directories = [
  "app/domains",
  "app/domains/shared",
  "app/domains/shared/public",
  "app/domains/shared/application",
  "app/domains/shared/application/use_cases",
  "app/domains/shared/application/event_handlers",
  "app/domains/shared/domain",
  "app/domains/shared/domain/entities",
  "app/domains/shared/domain/value_objects",
  "app/domains/shared/domain/events",
  "app/domains/shared/domain/repositories",
  "app/domains/shared/infrastructure",
  "app/domains/shared/infrastructure/active_record",
  "app/domains/shared/infrastructure/active_record/models",
  "app/domains/shared/infrastructure/repositories",
  "app/domains/shared/infrastructure/messaging",
  "app/domains/shared/presentation",
  "app/domains/shared/presentation/controllers",
  "app/domains/shared/presentation/serializers",
  "app/domains/shared/presentation/views",
  "app/models"
]

base_keep_files = base_directories.map { |dir| "#{dir}/.keep" } - ["app/domains/.keep", "app/models/.keep"]
base_keep_files.concat(["app/domains/.keep", "app/models/.keep"])

identity_directories = [
  "app/domains/identity",
  "app/domains/identity/public",
  "app/domains/identity/application",
  "app/domains/identity/application/use_cases",
  "app/domains/identity/application/event_handlers",
  "app/domains/identity/domain",
  "app/domains/identity/domain/entities",
  "app/domains/identity/domain/value_objects",
  "app/domains/identity/domain/events",
  "app/domains/identity/domain/repositories",
  "app/domains/identity/infrastructure",
  "app/domains/identity/infrastructure/active_record",
  "app/domains/identity/infrastructure/active_record/models",
  "app/domains/identity/infrastructure/repositories",
  "app/domains/identity/infrastructure/messaging",
  "app/domains/identity/presentation",
  "app/domains/identity/presentation/controllers",
  "app/domains/identity/presentation/serializers",
  "app/domains/identity/presentation/views"
]

identity_keep_files = identity_directories.map { |dir| "#{dir}/.keep" } - ["app/domains/identity/.keep"]
identity_keep_files << "app/domains/identity/.keep"

directories = base_directories.dup
keep_files = base_keep_files.dup

if @include_user_setup
  directories.concat(identity_directories)
  keep_files.concat(identity_keep_files)
end

remove_default_rails_layers(*directories_to_remove)
create_directory_tree(directories)
create_keep_files(keep_files)

create_file "app/domains/shared/public/api.rb", "# frozen_string_literal: true\n\nmodule Shared\n  module Public\n    module Api\n    end\n  end\nend\n"
create_file "app/domains/shared/package.yml", <<~YAML
  name: shared
  enforce_privacy: true
YAML

if @include_user_setup
  create_file "app/domains/identity/public/api.rb", "# frozen_string_literal: true\n\nmodule Identity\n  module Public\n    module Api\n    end\n  end\nend\n"
  create_file "app/domains/identity/package.yml", <<~YAML
    name: identity
    enforce_privacy: true
  YAML
end
