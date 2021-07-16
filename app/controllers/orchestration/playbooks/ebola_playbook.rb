# frozen_string_literal: true

# EbolaPlaybook: the Ebola playbook
module Orchestration::Playbooks::EbolaPlaybook
  include Orchestration::Playbooks::Templates::DiseaseTemplate

  NAME = :ebola

  PLAYBOOK = {
    label: 'Ebola',
    workflows: {
      exposure: { label: 'Exposure', base: INFECTIOUS[:workflows][:exposure], custom_options: {
        dashboard_tabs: {
          type: 'all'
        },
        other_properties: {
        }
      } }
    },
    system: {
      continuous_exposure_on: false
    },
    other_properties: {
    }
  }.freeze
end
