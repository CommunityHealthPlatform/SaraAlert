# frozen_string_literal: true

# Covid21Playbook: tests 'subset' type works
module Orchestration::Playbooks::Covid21Playbook
  include Orchestration::Playbooks::Templates::DiseaseTemplate

  NAME = :covid_21

  PLAYBOOK = {
    label: 'COVID-21',
    workflows: {
      exposure: { label: 'Exposure', base: INFECTIOUS[:workflows][:exposure], custom_options: {
        dashboard_tabs: {
          type: 'all'
        },
        other_properties: {
        }
      } },
      isolation: { label: 'Isolation', base: INFECTIOUS[:workflows][:isolation], custom_options: {
        dashboard_tabs: {
          type: 'subset',
          config: {
            set: %i[reporting closed]
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
