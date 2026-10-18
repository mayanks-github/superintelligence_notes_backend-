module Api
  module V1
    class SourcesController < ApplicationController
      def index
        sources = Source.visible.ordered
        render json: { sources: sources.map { |source| Payloads.source(source) } }
      end
    end
  end
end
