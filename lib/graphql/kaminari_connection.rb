# frozen_string_literal: true

require 'graphql'
require 'graphql/kaminari_connection/version'

module GraphQL
  module KaminariConnection
    class << self
      def included(klass)
        klass.extend ClassMethods
      end

      # @return [Class]
      def page_data_type
        @page_data_type ||= define_page_data_type
      end

      # If your schema already has 'PageData' type, you can change its name.
      attr_writer :page_data_type_name

      attr_writer :base_page_data_class

      private

      # The name of page data GraphQL type.
      #
      # @return [String]
      def page_data_type_name
        @page_data_type_name || 'PageData'
      end

      # @return [Class]
      def base_page_data_class
        @base_page_data_class || GraphQL::Schema::Object
      end

      # @return [Class]
      def define_page_data_type
        type_name = page_data_type_name
        Class.new(base_page_data_class) do
          graphql_name type_name
          description 'Information about pagination'

          field :current_page, 'Int', null: false
          field :is_first_page, 'Boolean', null: false, method: :first_page?
          field :is_last_page, 'Boolean', null: false, method: :last_page?
          field :is_out_of_range, 'Boolean', null: false, method: :out_of_range?
          field :limit_value, 'Int', null: false
          field :next_page, 'Int', null: true
          field :prev_page, 'Int', null: true
          field :total_pages, 'Int', null: false
        end
      end
    end

    module ClassMethods
      def kaminari_connection(params = {})
        {
          type: page_type,
          arguments: page_arguments,
          null: false
        }.merge(params)
      end

      # @return [Class]
      def base_page_class
        GraphQL::Schema::Object
      end

      private

      # @return [Class]
      def page_type
        @page_type ||= define_page_type
      end

      def page_arguments
        [
          [:page, type: 'Int', required: false],
          [:per, type: 'Int', required: false]
        ]
      end

      # @return [Class]
      def define_page_type
        type_name = graphql_name
        type_class = self
        page_data_type_class = KaminariConnection.page_data_type

        Class.new(base_page_class) do
          graphql_name "#{type_name}Page"
          description "Autogenerated page type for #{type_name}"

          field :page_data, page_data_type_class, null: false, method: :object
          field :items, [type_class], 'A list of items', null: false, method: :object
        end
      end
    end
  end
end
