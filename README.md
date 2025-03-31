# Inferno PS Suite Generator

A Ruby Gem provides a functionality to generate the Inferno test suite for IPS-like implementation guides.

It generates 3 test groups
1. $summary operation tests
2. $summary entries tests
3. $docref operation tests

You can check generated example for the AU PS IG here: https://github.com/hl7au/au-ps-inferno/tree/master/lib/au_ps_inferno/generated/0.1.0-preview

## Usage example

``` ruby
namespace :au_ps do
  desc 'Generate tests'
  task :generate do
    InfernoPsSuiteGenerator::Generator.generate(
      {
        title: 'AU PS',
        ig_identifier: 'hl7.fhir.au.ps',
        gem_name: 'au_ps_inferno',
        core_file_path: './lib/au_ps_inferno.rb',
        output_path: './lib/au_ps_inferno',
        test_module_name: 'AUPS',
        test_id_prefix: 'au_ps',
        test_kit_module_name: 'AUPSTestKit',
        test_suite_class_name: 'AUPSInferno',
        base_output_file_name: 'au_ps_inferno.rb',
        version: '0.1.0-preview',
        igs: 'hl7.fhir.au.ps#0.1.0-preview',
        tx_server_url: 'https://tx.dev.hl7.org.au/fhir',
        specific_profiles: {
          docref_op: 'http://hl7.org/fhir/uv/ipa/OperationDefinition/docref',
          summary_op: 'http://hl7.org/fhir/uv/ips/OperationDefinition/summary',
          ps_bundle: 'http://hl7.org.au/fhir/ps/StructureDefinition/au-ps-bundle',
          ps_composition: 'http://hl7.org.au/fhir/ps/StructureDefinition/au-ps-composition'
        }
      }
    )
  end
end
```

