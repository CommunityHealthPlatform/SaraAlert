# frozen_string_literal: true

# Covid195Playbook: tests workflow 'InvalidWorkflow' is not valid
module Orchestration::Playbooks::Covid195Playbook
  include Orchestration::Playbooks::Templates::DiseaseTemplate

  NAME = :covid_195

  PLAYBOOK = {
    label: 'COVID-195',
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
          type: 'all'
        }
      } },
      workflow: { label: 'InvalidWorkflow', base: INFECTIOUS[:workflows][:isolation], custom_options: {
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
