# frozen_string_literal: true

class ApiEndpointGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  argument :actions, type: :array, default: [], banner: "action action"

  def create_controller
    template "controller.rb.tt", "app/interfaces/http/api/v1/#{file_path}/#{file_name}_controller.rb"
  end

  def create_contract
    template "contract.rb.tt", "app/domains/#{file_path}/contracts/create_contract.rb"
  end

  def create_use_case
    template "use_case.rb.tt", "app/domains/#{file_path}/use_cases/process_request.rb"
  end

  def create_serializer
    template "serializer.rb.tt", "app/interfaces/http/api/v1/#{file_path}/serializers/#{file_name.singularize}_serializer.rb"
  end
end
