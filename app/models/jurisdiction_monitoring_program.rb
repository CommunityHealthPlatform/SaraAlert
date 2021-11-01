class JurisdictionMonitoringProgram < ApplicationRecord
    # has_and_belongs_to_many :jurisdictions, include: false
   belongs_to :jurisdiction
   belongs_to :monitoring_program


   before_validation :handle_default_before_create, on: [:create]
   before_validation :handle_default_before_update, on: [:update]


   def handle_default_before_create      
        relation = JurisdictionMonitoringProgram.where(
                        { monitoring_program_id: self.monitoring_program_id,
                          jurisdiction_id: self.jurisdiction_id } ).first

        # If there isn't another relation we're safe, so move on
        throw :abort unless relation.nil?

        other_default = JurisdictionMonitoringProgram.where(
                        { is_default: true,
                          jurisdiction_id: self.jurisdiction_id } ).first
        
        # If there isn't another default, we're okay too
        return if !self.is_default || other_default.nil?

        # If there is, change the other from default
        other_default[:default] = false
        other_default.save
   end

    def handle_default_before_update       
      other_default = JurisdictionMonitoringProgram.where(
                      { is_default: true,
                        jurisdiction_id: self.jurisdiction_id } ).first
      
      # If there isn't another default, we're okay too
      return if !self.is_default || other_default.nil?

      # If there is, change the other from default
      other_default[:is_default] = false
      other_default.save
   end
end