# frozen_string_literal: true

remove_default_rails_layers(
  "app/controllers",
  "app/models",
  "app/helpers",
  "app/assets",
  "app/views",
  "app/mailers"
)

create_directory_tree(
  [
    "app/domains/shared/contracts",
    "app/domains/shared/errors",
    "app/interfaces/http/controllers/api/v1",
    "app/interfaces/http/serializers",
    "spec/requests/api/v1"
  ]
)

create_keep_files(
  [
    "app/domains/shared/contracts/.keep",
    "app/domains/shared/errors/.keep",
    "app/interfaces/http/controllers/api/v1/.keep",
    "app/interfaces/http/serializers/.keep",
    "spec/requests/api/v1/.keep"
  ]
)
