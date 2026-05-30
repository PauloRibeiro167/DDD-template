# frozen_string_literal: true

apply "shared/template_helpers.rb"

create_directory_tree(
  [
    "app/services",
    "app/presenters",
    "app/components",
    "spec/system"
  ]
)

create_keep_files(
  [
    "app/services/.keep",
    "app/presenters/.keep",
    "app/components/.keep",
    "spec/system/.keep"
  ]
)
