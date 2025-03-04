# frozen_string_literal: true

require_relative 'naming'

module InfernoPsSuiteGenerator
  class Generator
    class StaticTestGenerator
      class << self
        def generate(suite_config, test_config)
          new(suite_config, test_config).generate
        end
      end

      attr_accessor :suite_config, :test_config

      def initialize(suite_config, test_config)
        self.suite_config = suite_config
        self.test_config = test_config
      end

      def template
        @template ||= File.read(File.join(__dir__, '..', 'templates', test_config[:template]))
      end

      def output
        @output ||= ERB.new(template).result(binding)
      end

      def base_output_file_name
        "#{class_name.underscore}.rb"
      end

      def output_file_directory
        test_config[:output_file_directory]
      end

      def output_file_name
        File.join(output_file_directory, base_output_file_name)
      end

      def output_test_list_file_name
        File.join(output_file_directory, 'metadata.yaml')
      end

      def test_kit_module_name
        suite_config[:test_kit_module_name]
      end

      def test_id
        test_config[:test_id]
      end

      def class_name
        test_config[:class_name]
      end

      def module_name
        test_config[:module_name]
      end

      def profile_url
        test_config[:profile_url]
      end

      def title
        test_config[:title]
      end

      def description
        test_config[:description]
      end

      def generate
        FileUtils.mkdir_p(output_file_directory)
        File.open(output_file_name, 'w') { |f| f.write(output) }

        data = File.exist?(output_test_list_file_name) ? YAML.load_file(output_test_list_file_name) || [] : []
        data = [] unless data.is_a?(Array)
        data << {
          test_id: test_id,
          file_name: output_file_name
        }
        File.open(output_test_list_file_name, 'w') { |file| file.write(data.to_yaml) }
      end
    end
  end
end
