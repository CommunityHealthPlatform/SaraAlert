module Orchestration::Playbooks::Covid20Playbook
  include Orchestration::Playbooks::Templates::DiseaseTemplate

  NAME = :covid_20

  PLAYBOOK = {
    label: 'COVID-20',
    workflows: {
      exposure: { label: 'Exposure', base: INFECTIOUS[:workflows][:exposure], custom_options: {
        dashboard_tabs: {
          type: 'all',
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
  }
end
