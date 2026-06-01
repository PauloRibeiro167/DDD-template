# frozen_string_literal: true

class Api::ErrorSerializer < Blueprinter::Base
  fields :code, :message, :details
end
