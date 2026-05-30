# frozen_string_literal: true

module Shared
  module Errors
    class NotFoundError < ApplicationError
      def initialize(message: "Recurso não encontrado", details: nil)
        super(
          message: message,
          code: "not_found",
          http_status: :not_found,
          details: details
        )
      end
    end
  end
end
