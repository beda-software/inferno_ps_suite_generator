# frozen_string_literal: true

require 'yaml'

require_relative 'naming'

module InfernoPsSuiteGenerator
  class Generator
    class SuiteGenerator
      class << self
        def generate(suite_config, group_config)
          new(suite_config, group_config).generate
        end
      end

      attr_accessor :suite_config, :group_config

      def initialize(suite_config, group_config)
        self.suite_config = suite_config
        self.group_config = group_config
      end

      def template
        @template ||= File.read(File.join(__dir__, '..', 'templates', group_config[:template]))
      end

      def output
        @output ||= ERB.new(template).result(binding)
      end

      def base_output_file_name
        "#{group_config[:file_name]}.rb"
      end

      def output_file_directory
        group_config[:output_file_directory]
      end

      def output_file_name
        File.join(output_file_directory, base_output_file_name)
      end

      def output_test_list_file_name
        File.join(output_file_directory, 'metadata.yaml')
      end

      def class_name
        group_config[:class_name]
      end

      def module_name
        group_config[:module_name]
      end

      def title
        group_config[:title]
      end

      def description
        group_config[:description]
      end

      def tx_server_url
        group_config[:tx_server_url]
      end

      def suite_id
        group_config[:suite_id]
      end

      def test_list
        group_config[:group_data]
      end

      def test_list_ids
        test_list.map { |item| item[:test_id] }
      end

      def group_id
        group_config[:group_id]
      end

      def test_list_file_names
        test_list.map { |item| item[:file_name] }
      end

      def entries_is_group
        group_config[:entries_is_group] == true
      end

      def igs_str
        group_config[:igs_str]
      end

      def generate
        FileUtils.mkdir_p(output_file_directory)
        File.open(output_file_name, 'w') { |f| f.write(output) }
      end
    end
  end
end
