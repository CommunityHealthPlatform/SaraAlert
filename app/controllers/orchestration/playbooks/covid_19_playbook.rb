module Orchestration::Playbooks::Covid19Playbook
  include Orchestration::Playbooks::Templates::DiseaseTemplate

  NAME = :covid_19

  PLAYBOOK = {
    label: 'COVID-19',
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
  }
end
