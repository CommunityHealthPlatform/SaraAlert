# frozen_string_literal: true

# Covid23Playbook: tests 'base' type works
module Orchestration::Playbooks::Covid23Playbook
  include Orchestration::Playbooks::Templates::DiseaseTemplate

  NAME = :covid_23

  PLAYBOOK = {
    label: 'COVID-23',
    workflows: {
      exposure: { label: 'Exposure', base: INFECTIOUS[:workflows][:exposure], custom_options: {
        dashboard_tabs: {
          type: 'base',
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
      } }
    },
    system: {
      continuous_exposure_on: true
    },
    other_properties: {
    }
  }.freeze
end
