# frozen_string_literal: true

require 'yaml'
require 'fileutils'

require_relative 'inferno_ps_suite_generator/version'
require_relative 'inferno_ps_suite_generator/ig_loader'
require_relative 'inferno_ps_suite_generator/entry_test'
require_relative 'inferno_ps_suite_generator/composition_section.rb'

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
      CompositionSectionTestGenerator.generate(metadata, suite_config[:output_path], suite_config)
      EntryTestGenerator.generate(metadata, suite_config[:output_path], suite_config)
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

        result = {
          resource_type: resource_type,
          resource_profile: resource_element.type.first.profile.first,
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
