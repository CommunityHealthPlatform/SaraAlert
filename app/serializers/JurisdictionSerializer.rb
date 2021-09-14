class JurisdictionSerializer < ActiveModel::Serializer
    attributes :id
    # has_many :monitoring_programs, class_name: 'MonitoringProgram', serializer: MonitoringProgramSerializer
end 