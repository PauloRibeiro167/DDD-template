# frozen_string_literal: true

module Shared
  module Errors
    class ConflictError < ApplicationError
      def initialize(message: "Conflito de recurso", details: nil)
        super(
          message: message,
          code: "conflict",
          http_status: :conflict,
          details: details
        )
      end
    end
  end
end
