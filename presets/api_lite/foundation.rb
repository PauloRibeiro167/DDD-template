# frozen_string_literal: true

copy_template_files(
  {
    "presets/api_lite/files/app/domains/shared/contracts/application_contract.rb" => "app/domains/shared/contracts/application_contract.rb",
    "presets/api_lite/files/app/domains/shared/errors/application_error.rb" => "app/domains/shared/errors/application_error.rb",
    "presets/api_lite/files/app/domains/shared/errors/conflict_error.rb" => "app/domains/shared/errors/conflict_error.rb",
    "presets/api_lite/files/app/domains/shared/errors/forbidden_error.rb" => "app/domains/shared/errors/forbidden_error.rb",
    "presets/api_lite/files/app/domains/shared/errors/not_found_error.rb" => "app/domains/shared/errors/not_found_error.rb",
    "presets/api_lite/files/app/domains/shared/errors/unauthorized_error.rb" => "app/domains/shared/errors/unauthorized_error.rb",
    "presets/api_lite/files/app/domains/shared/errors/validation_error.rb" => "app/domains/shared/errors/validation_error.rb",
    "presets/api_lite/files/app/interfaces/http/api/base_controller.rb" => "app/interfaces/http/api/base_controller.rb",
    "presets/api_lite/files/app/interfaces/http/api/error_serializer.rb" => "app/interfaces/http/api/error_serializer.rb"
  }
)
