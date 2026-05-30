# frozen_string_literal: true

module Shared
  module Errors
    class ValidationError < ApplicationError
      def initialize(message: "Falha de validação", details: {})
        super(
          message: message,
          code: "validation_error",
          http_status: :unprocessable_entity,
          details: details
        )
      end
    end
  end
end
