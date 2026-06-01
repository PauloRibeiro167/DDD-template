# frozen_string_literal: true

create_directory_tree(
  [
    "app/domains/shared/contracts",
    "app/domains/shared/errors",
    "app/domains/identity/models",
    "app/domains/identity/policies",
    "app/domains/identity/jobs",
    "app/domains/identity/services",
    "app/interfaces/http/api/v1/identity",
    "app/interfaces/http/api/v1/identity/serializers",
    "app/interfaces/http/api/serializers",
    "app/infrastructure/persistence",
    "app/infrastructure/security",
    "spec/requests/api/v1"
  ]
)

create_keep_files(
  [
    "app/domains/shared/contracts/.keep",
    "app/domains/shared/errors/.keep",
    "app/domains/identity/models/.keep",
    "app/domains/identity/policies/.keep",
    "app/domains/identity/jobs/.keep",
    "app/domains/identity/services/.keep",
    "app/interfaces/http/api/v1/identity/.keep",
    "app/interfaces/http/api/v1/identity/serializers/.keep",
    "app/interfaces/http/api/serializers/.keep",
    "app/infrastructure/persistence/.keep",
    "app/infrastructure/security/.keep",
    "spec/requests/api/v1/.keep"
  ]
)
