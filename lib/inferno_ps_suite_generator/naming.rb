# frozen_string_literal: true

module InfernoPsSuiteGenerator
  class Generator
    module Naming
      class << self
        def snake_case_for_profile(group_metadata)
          group_metadata[:resource_type].underscore
        end

        def upper_camel_case_for_profile(group_metadata)
          snake_case_for_profile(group_metadata).camelize
        end
      end
    end
  end
end
