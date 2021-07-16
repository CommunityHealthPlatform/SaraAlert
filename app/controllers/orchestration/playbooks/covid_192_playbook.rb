# frozen_string_literal: true

# Covid192Playbook: tests exposure workflow with unsupported tab is not valid
module Orchestration::Playbooks::Covid192Playbook
  include Orchestration::Playbooks::Templates::DiseaseTemplate

  NAME = :covid_192

  PLAYBOOK = {
    label: 'COVID-192',
    workflows: {
      exposure: { label: 'Exposure', base: INFECTIOUS[:workflows][:exposure], custom_options: {
        dashboard_tabs: {
          type: 'subset',
          config: {
            set: %i[symptomatic non_reporting unsupported]
          }
        },
        other_properties: {
        }
      } },
      isolation: { label: 'Isolation', base: INFECTIOUS[:workflows][:isolation], custom_options: {
        dashboard_tabs: {
          type: 'all'
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
