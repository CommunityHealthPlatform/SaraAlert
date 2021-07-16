# frozen_string_literal: true

# Covid194Playbook: tests isloation workflow with unsupported tab is not valid
module Orchestration::Playbooks::Covid194Playbook
  include Orchestration::Playbooks::Templates::DiseaseTemplate

  NAME = :covid_194

  PLAYBOOK = {
    label: 'COVID-194',
    workflows: {
      exposure: { label: 'Exposure', base: INFECTIOUS[:workflows][:exposure], custom_options: {
        dashboard_tabs: {
          type: 'subset',
          config: {
            set: %i[symptomatic non_reporting]
          }
        },
        other_properties: {
        }
      } },
      isolation: { label: 'Isolation', base: INFECTIOUS[:workflows][:isolation], custom_options: {
        dashboard_tabs: {
          type: 'subset',
          config: {
            set: %i[symptomatic non_reporting]
          }
        }
      } }
    },
    system: {
      continuous_exposure_on: true
    },
    other_properties: {
    }
  }.freeze
end
