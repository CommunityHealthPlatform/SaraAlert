# frozen_string_literal: true

require 'digest'

# Jurisdiction: jurisdiction model
class Jurisdiction < ApplicationRecord
  has_ancestry

  # Immediate patients are those just in this jurisdiction
  has_many :immediate_patients, class_name: 'Patient', dependent: nil

  # Find the USA Jurisdiction
  def self.root
    Jurisdiction.find_by(name: 'USA')
  end

  # All patients are all those in this or descendent jurisdictions (including purged)
  def all_patients_including_purged
    Patient.where(jurisdiction_id: subtree_ids)
  end

  # All patients are all those in this or descendent jurisdictions (excluding purged)
  def all_patients_excluding_purged
    all_patients_including_purged.where(purged: false)
  end

  # All users that are in this or descendent jurisdictions
  def all_users
    User.where(jurisdiction_id: subtree_ids)
  end

  # All patients that were in the jurisdiction before (but were transferred), and are not currently in the subtree
  def transferred_out_patients
    Patient.where(purged: false, id: Transfer.where(from_jurisdiction_id: subtree_ids).select(:patient_id)).where.not(jurisdiction_id: subtree_ids + [id])
  end

  # All patients that were transferred into the jurisdiction in the last 24 hours
  def transferred_in_patients
    Patient.where(purged: false, id: Transfer.where(to_jurisdiction_id: subtree_ids + [id])
                              .where.not(from_jurisdiction_id: subtree_ids + [id])
                              .where('created_at > ?', 24.hours.ago).select(:patient_id))
           .where(jurisdiction_id: subtree_ids + [id])
  end

  # This will return the first available contact info (email, phone, and/or webpage)
  # discovered along this jurisdiction's path
  def contact_info
    contact_info = { email: '', phone: '', webpage: '' }
    # Iterate over path in reverse so that we will be starting _at_ the current jurisdiction
    path&.reverse&.each do |jur|
      unless jur.phone.blank? && jur.email.blank? && jur.webpage.blank?
        contact_info[:email] = jur.email || ''
        contact_info[:phone] = jur.phone || ''
        contact_info[:webpage] = jur.webpage || ''
        break
      end
    end
    contact_info
  end
end
