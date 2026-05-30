# frozen_string_literal: true

module Shared
  module Errors
    class ForbiddenError < ApplicationError
      def initialize(message: "Acesso negado", details: nil)
        super(
          message: message,
          code: "forbidden",
          http_status: :forbidden,
          details: details
        )
      end
    end
  end
end
