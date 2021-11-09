require 'securerandom'
require 'io/console'
require 'digest'
require 'json'

namespace :admin do

  desc "Import/Update Jurisdictions"
  task import_or_update_jurisdictions: :environment do
    ActiveRecord::Base.transaction do

      config_name = ENV['PERFORMANCE'].nil? || ENV['PERFORMANCE'] == 'false' ? 'jurisdictions' : 'performance_jurisdictions'

      YAML.load_file("config/sara/#{config_name}.yml").each do |jur_name, jur_values|
        parse_jurisdiction(nil, jur_name, jur_values)
      end

    end
  end

  def parse_jurisdiction(parent, jur_name, jur_values)
    jurisdiction = nil
    matching_jurisdictions = Jurisdiction.where(name: jur_name)
    matching_jurisdictions.each do |matching_jurisdiction|
      # Also works for the case where parent is nil ie: top-level jurisdiction
      if matching_jurisdiction.parent&.path == parent&.path
        jurisdiction = matching_jurisdiction
        break
      end
    end
    # Create jurisdiction for it does not already exist
    if jurisdiction == nil
      jurisdiction = Jurisdiction.create(name: jur_name , parent: parent)
      jurisdiction_path = jurisdiction.path&.map(&:name)&.join(', ')

      # Create a 10 character, url-safe, base-64 string based on the SHA-256 hash of the jurisdiction path
      unique_identifier = Base64::urlsafe_encode64([[Digest::SHA256.hexdigest(jurisdiction_path)].pack('H*')].pack('m0'))[0, 10]

      # Warn user if collision has occured
      if Jurisdiction.where(unique_identifier: unique_identifier).where.not(id: jurisdiction.id).any?
        raise "JURISDICTION IDENTIFIER HASH COLLISION FOR: #{jurisdiction_path}"
      end

      jurisdiction.update(unique_identifier: unique_identifier, path: jurisdiction_path)
    end

    # Parse and add symptoms list to jurisdiction if included
    jur_symps = nil
    if jur_values != nil
      jur_symps = jur_values['symptoms']
      jurisdiction.email = jur_values['email'] || ''
      jurisdiction.phone = jur_values['phone'] || ''
      jurisdiction.webpage = jur_values['webpage'] || ''
      jurisdiction.message = jur_values['message'] || ''
    end

    jurisdiction.save


    # Parse and recursively create children jurisdictions if  included
    children_jurs = nil
    if jur_values != nil
      children_jurs = jur_values['children']
    end
    if children_jurs != nil
      children_jurs.each do |child_jur_name, child_jur_vals|
        parse_jurisdiction(jurisdiction, child_jur_name, child_jur_vals)
      end
    end

  end
end
