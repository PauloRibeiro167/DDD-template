# frozen_string_literal: true

module Shared
  module Errors
    class ApplicationError < StandardError
      attr_reader :code, :details, :http_status

      def initialize(message:, code:, http_status:, details: nil)
        super(message)
        @code = code
        @details = details
        @http_status = http_status
      end
    end
  end
end
