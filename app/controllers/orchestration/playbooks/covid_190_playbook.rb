# frozen_string_literal: true

# Covid190Playbook: tests playbook without name is not valid
module Orchestration::Playbooks::Covid190Playbook
  include Orchestration::Playbooks::Templates::DiseaseTemplate

  NAME = :covid_190

  PLAYBOOK = {
    label: '',
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
      } }
    },
    system: {
      continuous_exposure_on: true
    },
    other_properties: {
    }
  }.freeze
end
