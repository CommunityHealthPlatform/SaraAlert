class JurisdictionMonitoringProgram < ApplicationRecord
  # has_and_belongs_to_many :jurisdictions, include: false
  belongs_to :jurisdiction
  belongs_to :monitoring_program

  before_validation :handle_default, on: %i[create update]

  def handle_default
    relation = JurisdictionMonitoringProgram.where(
      { monitoring_program_id: monitoring_program_id,
        jurisdiction_id: jurisdiction_id }
    ).first

    # If there isn't another relation we're safe, so move on
    throws :abort unless relation.nil?

    other_default = JurisdictionMonitoringProgram.where(
      { is_default: true,
        jurisdiction_id: jurisdiction_id }
    ).first

    # If there isn't another default, we're okay too
    return if other_default.nil?

    # If there is, change the other from default
    other_default[:default] = false
    other_default.save
  end
end
