module Orchestration::Playbooks::Covid196Playbook
  include Orchestration::Playbooks::Templates::DiseaseTemplate

  NAME = :covid_196

  PLAYBOOK = {
    label: 'COVID-196',
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
          type: 'invalid'
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
