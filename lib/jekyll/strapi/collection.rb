require "net/http"
require "ostruct"
require "json"

module Jekyll
  module Strapi
    class StrapiCollection
      attr_accessor :collection_name, :config

      def initialize(site, collection_name, config)
        @site = site
        @collection_name = collection_name
        @config = config
      end

      def generate?
        @config['output'] || false
      end

      def each
        # Initialize the HTTP query
        path = "/#{@config['type'] || @collection_name}?_limit=10000"
        uri = URI("#{@site.endpoint}#{path}")
        Jekyll.logger.info "Jekyll Strapi:", "Fetching entries from #{uri}"
        # Get entries
        response = Net::HTTP.get_response(uri)
        # Check response code
        if response.code == "200"
          result = JSON.parse(response.body, object_class: OpenStruct)
        elsif response.code == "401"
          raise "The Strapi server sent a error with the following status: #{response.code}. Please make sure you authorized the API access in the Users & Permissions section of the Strapi admin panel."
        else
          raise "The Strapi server sent a error with the following status: #{response.code}. Please make sure it is correctly running."
        end

        Jekyll.logger.info "Jekyll Strapi:", "Verifying Update"

        if result.data.kind_of?(Array)
          Jekyll.logger.info "Jekyll Strapi:", "Retrieving array"
          # Add necessary properties
          result.data.each do |document|
            document.type = collection_name
            document.collection = collection_name
            document.id ||= document._id
            document.url = @site.strapi_link_resolver(collection_name, document)
            Jekyll.logger.info "Jekyll Strapi:", "Result.data: #{result.data}"
          end

          result.data.each {|x| yield(x)}
        else
          Jekyll.logger.info "Jekyll Strapi:", "Retrieving single type"
          # Add necessary properties
          result.data do |document|
            document.type = collection_name
            document.collection = collection_name
            document.id ||= document._id
            document.url = @site.strapi_link_resolver(collection_name, document)
          end

          Jekyll.logger.info "Jekyll Strapi:", "Collection Name: #{collection_name}"
          Jekyll.logger.info "Jekyll Strapi:", "Result.data: #{result.data}"

          result.data {|x| yield(x)}
        end
      end
    end
  end
end
