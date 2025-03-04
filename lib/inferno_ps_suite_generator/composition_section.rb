# frozen_string_literal: true

require 'yaml'

require_relative 'naming'

module InfernoPsSuiteGenerator
  class Generator
    class CompositionSectionTestGenerator
      class << self
        def generate(ig_metadata, base_output_dir, suite_config)
          composition_data = ig_metadata.find { |entry_data| entry_data[:resource_type] == 'Composition' }
          composition_data[:sections].each do |composition_section_data|
            new(composition_section_data, base_output_dir, suite_config).generate
          end
        end
      end

      attr_accessor :group_metadata, :base_output_dir, :suite_config

      def initialize(group_metadata, base_output_dir, suite_config)
        self.group_metadata = group_metadata
        self.base_output_dir = base_output_dir
        self.suite_config = suite_config
      end

      def template
        @template ||= File.read(File.join(__dir__, '..', 'templates', 'section.rb.erb'))
      end

      def output
        @output ||= ERB.new(template).result(binding)
      end

      def base_output_file_name
        "#{class_name.underscore}.rb"
      end

      def output_file_directory
        File.join(base_output_dir, 'generated', suite_config[:version], 'summary_operation_group')
      end

      def output_file_name
        File.join(output_file_directory, base_output_file_name)
      end

      def output_test_list_file_name
        File.join(output_file_directory, 'metadata.yaml')
      end

      def profile_identifier
        'composition'
      end

      def test_kit_module_name
        suite_config[:test_kit_module_name]
      end

      def test_id
        "#{suite_config[:test_id_prefix]}_#{group_metadata[:title].gsub(' ',
                                                                        '_').downcase}_#{profile_identifier}_section_test"
      end

      def class_name
        "#{suite_config[:test_suite_class_name]}#{group_metadata[:title].gsub(' ', '')}CompositionSectionTest"
      end

      def module_name
        "#{suite_config[:test_module_name]}#{group_metadata.reformatted_version.upcase}"
      end

      def resource_type
        group_metadata[:resource_type]
      end

      def optional?
        group_metadata[:min].zero?
      end

      def profile_url
        group_metadata[:profiles].first
      end

      def title
        "Validate #{group_metadata[:title]}"
      end

      def description
        "This test verifies that the #{group_metadata[:title]} within the Composition entry of a $summary Bundle is correctly structured. It extracts the references listed in the section, checks that the corresponding resources exist in the Bundle, and ensures they conform to the expected resource type and profile requirements."
      end

      def section_code
        group_metadata[:code][:code]
      end

      def target_resources_and_profiles
        group_metadata[:entries].map do |entry|
          "#{entry[:resource_type]}::#{entry[:profile]}"
        end.join(';')
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

        # group_metadata.add_test(
        #   id: test_id,
        #   file_name: base_output_file_name
        # )
      end
    end
  end
end
