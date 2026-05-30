# frozen_string_literal: true

module Shared
  module Contracts
    class ApplicationContract < Dry::Validation::Contract
      UUID_FORMAT = /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

      config.messages.default_locale = :"pt-BR"
      config.messages.top_namespace = :dry_validation

      register_macro(:trimmed_string) do
        next unless value.is_a?(String)

        values[key_name] = value.strip
      end

      register_macro(:downcased_email) do
        next unless value.is_a?(String)

        normalized_value = value.strip.downcase
        values[key_name] = normalized_value
        key.failure("deve ser um e-mail válido") unless URI::MailTo::EMAIL_REGEXP.match?(normalized_value)
      end

      register_macro(:positive_integer) do
        key.failure("deve ser um inteiro positivo") unless value.is_a?(Integer) && value.positive?
      end

      register_macro(:uuid) do
        next if value.is_a?(String) && value.match?(UUID_FORMAT)

        key.failure("deve ser um UUID válido")
      end

      register_macro(:iso8601_datetime) do
        DateTime.iso8601(value.to_s)
      rescue ArgumentError
        key.failure("deve ser uma data/hora ISO8601 válida")
      end

      def error_payload(result)
        result.errors.to_h
      end
    end
  end
end
