# frozen_string_literal: true

require_relative 'naming'

module InfernoPsSuiteGenerator
  class Generator
    class EntryTestGenerator
      class << self
        def generate(ig_metadata, base_output_dir, suite_config)
          ig_metadata.reject { |entry_data| entry_data[:resource_type] == 'Composition' }.each do |entry_data|
            new(entry_data, base_output_dir, suite_config).generate
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
        @template ||= File.read(File.join(__dir__, '..', 'templates', 'entry.rb.erb'))
      end

      def output
        @output ||= ERB.new(template).result(binding)
      end

      def base_output_file_name
        "#{class_name.underscore}.rb"
      end

      def output_file_directory
        File.join(base_output_dir, 'generated', suite_config[:version], 'entries_group')
      end

      def output_file_name
        File.join(output_file_directory, base_output_file_name)
      end

      def output_test_list_file_name
        File.join(output_file_directory, 'metadata.yaml')
      end

      def title
        group_metadata[:title]
      end

      def profile_identifier
        title.gsub('(', '').gsub(')', '').gsub('/', '').gsub(' - ', ' ').gsub(' ', '_').downcase
      end

      def test_kit_module_name
        suite_config[:test_kit_module_name]
      end

      def test_id
        "#{suite_config[:test_id_prefix]}_#{profile_identifier}_entry_test"
      end

      def class_name
        "#{profile_identifier.split('_').map(&:capitalize).join}EntryTest"
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
        group_metadata[:resource_profile]
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
