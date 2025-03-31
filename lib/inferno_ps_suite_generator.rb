# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require 'ostruct'

require_relative 'inferno_ps_suite_generator/version'
require_relative 'inferno_ps_suite_generator/ig_loader'
require_relative 'inferno_ps_suite_generator/entry_test'
require_relative 'inferno_ps_suite_generator/composition_section'
require_relative 'inferno_ps_suite_generator/group_generator'
require_relative 'inferno_ps_suite_generator/static_test_generator'
require_relative 'inferno_ps_suite_generator/suite_generator'

module InfernoPsSuiteGenerator
  class Generator
    def self.generate(suite_config)
      ig_packages = Dir.glob(File.join(Dir.pwd, 'lib', suite_config[:gem_name], 'igs', '*.tgz'))

      ig_packages.each do |ig_package|
        new(ig_package, suite_config).generate
      end
    end

    attr_accessor :ig_resources, :ig_metadata, :ig_file_name, :suite_config

    def initialize(ig_file_name, suite_config)
      self.ig_file_name = ig_file_name
      self.suite_config = suite_config
    end

    def generate
      puts "Generating tests for IG #{File.basename(ig_file_name)}"
      load_ig_package
      metadata = extract_metadata
      generate_summary_operation_tests(metadata, suite_config)
      generate_docref_operation_tests(suite_config)
      EntryTestGenerator.generate(metadata, suite_config[:output_path], suite_config)
      generate_suite(suite_config, [generate_summary_operation_group(suite_config),
                                    generate_summary_entries_group(suite_config),
                                    generate_docref_group(suite_config)].flatten)
    end

    def generate_summary_operation_tests(metadata, suite_config)
      generate_summary_operation_test(suite_config)
      generate_summary_operation_return_bundle_test(suite_config)
      generate_summary_operation_valid_composition_test(suite_config)
      CompositionSectionTestGenerator.generate(metadata, suite_config[:output_path], suite_config)
    end

    def generate_docref_operation_tests(suite_config)
      generate_docref_exist(suite_config)
      generate_docref_success_test(suite_config)
    end

    def generate_docref_exist(suite_config)
      StaticTestGenerator.generate(
        suite_config,
        {
          title: 'Server declares support for $docref operation in CapabilityStatement',
          description: 'The IPS Server declares support for DocumentReference/$docref operation in its server CapabilityStatement',
          template: 'docref_operation_support.rb.erb',
          file_name: 'au_ps_docref_operation_support',
          output_file_directory: File.join(suite_config[:output_path], 'generated', suite_config[:version],
                                           'docref_operation_group'),
          class_name: 'DocrefOperationSupport',
          test_id: 'au_ps_docref_operation_support',
          profile_url: suite_config.dig(:specific_profiles, :docref_op),
          module_name: suite_config[:test_kit_module_name]
        }
      )
    end

    def generate_docref_success_test(suite_config)
      StaticTestGenerator.generate(
        suite_config,
        {
          title: 'Server responds successfully to a $docref operation',
          description: 'This test creates a $docref operation request for a patient.  Note that this currently does not request an IPS bundle specifically therefore does not validate the content.',
          template: 'docref_operation_success.rb.erb',
          file_name: 'au_ps_docref_operation_success',
          output_file_directory: File.join(suite_config[:output_path], 'generated', suite_config[:version],
                                           'docref_operation_group'),
          class_name: 'DocrefOperationSuccess',
          test_id: 'au_ps_docref_operation_success',
          profile_url: '',
          module_name: suite_config[:test_kit_module_name]
        }
      )
    end

    def generate_summary_operation_group(suite_config)
      GroupGenerator.generate(
        suite_config,
        {
          title: '$summary Operation Tests',
          description: 'Verify support for the $summary operation as as described in the AU PS Guidance',
          template: 'summary_operation_group.rb.erb',
          file_name: 'au_ps_summary_operation_group',
          output_file_directory: File.join(suite_config[:output_path], 'generated', suite_config[:version],
                                           'summary_operation_group'),
          class_name: 'SummaryOperationGroup',
          group_id: 'au_ps_summary_operation',
          module_name: suite_config[:test_kit_module_name]
        }
      )
    end

    def generate_summary_entries_group(suite_config)
      GroupGenerator.generate(
        suite_config,
        {
          title: '$summary Entries Tests',
          description: 'A set of tests to check entries from $summary for read action and validate them according to profile specified in the AU PS Implementation Guide',
          template: 'summary_operation_group.rb.erb',
          file_name: 'au_ps_entries_group',
          output_file_directory: File.join(suite_config[:output_path], 'generated', suite_config[:version],
                                           'entries_group'),
          class_name: 'EntriesGroup',
          group_id: 'au_ps_entries',
          module_name: suite_config[:test_kit_module_name]
        }
      )
    end

    def generate_docref_group(suite_config)
      GroupGenerator.generate(
        suite_config,
        {
          title: '$docref Operation Tests',
          description: 'Verify support for the $docref operation as as described in the AU PS Guidance',
          template: 'summary_operation_group.rb.erb',
          file_name: 'au_ps_docref_group',
          output_file_directory: File.join(suite_config[:output_path], 'generated', suite_config[:version],
                                           'docref_operation_group'),
          class_name: 'DocRefOperation',
          group_id: 'au_ps_docref_operation_group',
          module_name: suite_config[:test_kit_module_name]
        }
      )
    end

    def generate_suite(suite_config, group_data)
      SuiteGenerator.generate(
        suite_config,
        {
          title: 'AU PS Inferno Suite',
          description: 'AU PS Infenro Suite consist of $summary tests, $summary entries tests and $docref tests',
          template: 'suite.rb.erb',
          file_name: 'au_ps_suite',
          output_file_directory: File.join(suite_config[:output_path], 'generated', suite_config[:version]),
          suite_id: 'au_ps_suite',
          group_data: group_data,
          igs_str: suite_config[:igs],
          module_name: suite_config[:test_kit_module_name],
          tx_server_url: suite_config[:tx_server_url]
        }
      )
    end

    def generate_summary_operation_test(suite_config)
      StaticTestGenerator.generate(
        suite_config,
        {
          title: 'Server declares support for $summary operation in CapabilityStatement',
          description: 'The Server declares support for Patient/[id]/$summary operation in its server CapabilityStatement',
          template: 'summary_operation_support.rb.erb',
          file_name: 'au_ps_summary_operation_support',
          output_file_directory: File.join(suite_config[:output_path], 'generated', suite_config[:version],
                                           'summary_operation_group'),
          class_name: 'SummaryOperationSupport',
          test_id: 'au_ps_summary_operation_support',
          profile_url: suite_config.dig(:specific_profiles, :summary_op),
          module_name: suite_config[:test_kit_module_name]
        }
      )
    end

    def generate_summary_operation_return_bundle_test(suite_config)
      StaticTestGenerator.generate(
        suite_config,
        {
          title: 'Server returns Bundle resource for Patient/[id]/$summary GET operation',
          description: 'Server returns a valid Bundle resource as successful result of $summary operation.',
          template: 'summary_operation_return_bundle.rb.erb',
          file_name: 'au_ps_summary_operation_return_bundle',
          output_file_directory: File.join(suite_config[:output_path], 'generated', suite_config[:version],
                                           'summary_operation_group'),
          class_name: 'SummaryOperationReturnBundle',
          test_id: 'au_ps_summary_operation_return_bundle',
          profile_url: suite_config.dig(:specific_profiles, :ps_bundle),
          module_name: suite_config[:test_kit_module_name]
        }
      )
    end

    def generate_summary_operation_valid_composition_test(suite_config)
      StaticTestGenerator.generate(
        suite_config,
        {
          title: 'Server returns Bundle resource containing valid Composition entry',
          description: 'Server return valid Composition resource in the Bundle as first entry',
          template: 'summary_operation_valid_composition.rb.erb',
          file_name: 'au_ps_summary_operation_valid_composition',
          output_file_directory: File.join(suite_config[:output_path], 'generated', suite_config[:version],
                                           'summary_operation_group'),
          class_name: 'SummaryOperationValidComposition',
          test_id: 'au_ps_summary_operation_valid_composition',
          profile_url: suite_config.dig(:specific_profiles, :ps_composition),
          module_name: suite_config[:test_kit_module_name]
        }
      )
    end

    def load_ig_package
      FHIR.logger = Logger.new('/dev/null')
      self.ig_resources = IGLoader.new(ig_file_name, suite_config).load
    end

    def extract_composition_metadata(composition_sd)
      sections_elements = composition_sd.snapshot.element.select do |element|
        element.path == 'Composition.section' and element.id != 'Composition.section'
      end
      sections_elements.map do |section_element|
        current_section_entry_elements = composition_sd.snapshot.element.select do |element|
          element.id.include? "#{section_element.id}.entry" and element.id != "#{section_element.id}.entry"
        end
        current_section_entry_code_element = composition_sd.snapshot.element.find do |element|
          element.id.include? "#{section_element.id}.code"
        end

        target_profiles = current_section_entry_elements.map { |el| el.type.first.targetProfile.first }

        entries = target_profiles.map do |profile|
          {
            profile: profile,
            resource_type: ig_resources.resources_by_type['StructureDefinition'].find do |sd|
              sd.url == profile
            end.type
          }
        end

        {
          title: section_element.short,
          definition: section_element.definition,
          min: section_element.min,
          max: section_element.max,
          code: {
            code: current_section_entry_code_element.patternCodeableConcept.coding.first.code,
            system_value: current_section_entry_code_element.patternCodeableConcept.coding.first.system
          },
          entries: entries
        }
      end
    end

    def find_sd_by_profile(profile_url)
      ig_resources.resources_by_type['StructureDefinition'].find { |sd| sd.url == profile_url }
    end

    def extract_metadata
      composition_metadata = extract_composition_metadata(ig_resources.resources_by_type['StructureDefinition'].find do |entry|
        entry.type == 'Composition'
      end)
      bundle_structure_definition = ig_resources.resources_by_type['StructureDefinition'].find do |entry|
        entry.type == 'Bundle'
      end
      bundle_structure_definition_all_elements = bundle_structure_definition.snapshot.element
      bundle_structure_definition_elements = bundle_structure_definition.snapshot.element.select do |element|
        element.base.path == 'Bundle.entry' and element.id != 'Bundle.entry'
      end
      bundle_structure_definition_elements_ids = bundle_structure_definition_elements.map(&:id)
      entries = bundle_structure_definition_elements_ids.map do |element_id|
        resource_element_id = "#{element_id}.resource"
        resource_element_base = bundle_structure_definition_all_elements.find { |element| element.id == element_id }
        resource_element = bundle_structure_definition_all_elements.find { |element| element.id == resource_element_id }

        resource_type = resource_element.type.first.code
        current_profile = resource_element.type.first.profile.first
        current_sd = find_sd_by_profile(current_profile)
        title = current_sd.title if current_sd && current_profile

        result = {
          title: title || resource_type,
          resource_type: resource_type,
          resource_profile: current_profile,
          min: resource_element_base.min,
          max: resource_element_base.max
        }

        result[:sections] = composition_metadata if resource_type == 'Composition'

        result
      end

      result_filepath = "#{suite_config[:output_path]}/generated/#{suite_config[:version]}/metadata.yaml"
      FileUtils.mkdir_p(File.dirname(result_filepath))
      File.write(result_filepath, entries.to_yaml)
      entries
    end
  end
end
