# frozen_string_literal: true

module Shared
  module Errors
    class UnauthorizedError < ApplicationError
      def initialize(message: "Não autorizado", details: nil)
        super(
          message: message,
          code: "unauthorized",
          http_status: :unauthorized,
          details: details
        )
      end
    end
  end
end
