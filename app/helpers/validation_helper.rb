# frozen_string_literal: true

# ValidationHelper: Helper constants and methods for validation.
module ValidationHelper # rubocop:todo Metrics/ModuleLength
  SEX_ABBREVIATIONS = {
    M: 'Male',
    F: 'Female',
    U: 'Unknown',
    UNREPORTED: 'Unknown'
  }.freeze

  STATE_ABBREVIATIONS = {
    AL: 'Alabama',
    AK: 'Alaska',
    AS: 'American Samoa',
    AZ: 'Arizona',
    AR: 'Arkansas',
    CA: 'California',
    CO: 'Colorado',
    CT: 'Connecticut',
    DE: 'Delaware',
    DC: 'District of Columbia',
    FM: 'Federated States of Micronesia',
    FL: 'Florida',
    GA: 'Georgia',
    GU: 'Guam',
    HI: 'Hawaii',
    ID: 'Idaho',
    IL: 'Illinois',
    IN: 'Indiana',
    IA: 'Iowa',
    KS: 'Kansas',
    KY: 'Kentucky',
    LA: 'Louisiana',
    ME: 'Maine',
    MH: 'Marshall Islands',
    MD: 'Maryland',
    MA: 'Massachusetts',
    MI: 'Michigan',
    MN: 'Minnesota',
    MS: 'Mississippi',
    MO: 'Missouri',
    MT: 'Montana',
    NE: 'Nebraska',
    NV: 'Nevada',
    NH: 'New Hampshire',
    NJ: 'New Jersey',
    NM: 'New Mexico',
    NY: 'New York',
    NC: 'North Carolina',
    ND: 'North Dakota',
    MP: 'Northern Mariana Islands',
    OH: 'Ohio',
    OK: 'Oklahoma',
    OR: 'Oregon',
    PW: 'Palau',
    PA: 'Pennsylvania',
    PR: 'Puerto Rico',
    RI: 'Rhode Island',
    SC: 'South Carolina',
    SD: 'South Dakota',
    TN: 'Tennessee',
    TX: 'Texas',
    UT: 'Utah',
    VT: 'Vermont',
    VI: 'Virgin Islands',
    VA: 'Virginia',
    WA: 'Washington',
    WV: 'West Virginia',
    WI: 'Wisconsin',
    WY: 'Wyoming'
  }.freeze

  VALID_STATES = STATE_ABBREVIATIONS.values

  RACE_OPTIONS = {
    non_exclusive: [
      { race: :white, label: 'WHITE' },
      { race: :black_or_african_american, label: 'BLACK OR AFRICAN AMERICAN' },
      { race: :american_indian_or_alaska_native, label: 'AMERICAN INDIAN OR ALASKA NATIVE' },
      { race: :asian, label: 'ASIAN' },
      { race: :native_hawaiian_or_other_pacific_islander, label: 'NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER' },
      { race: :race_other, label: 'OTHER' }
    ],
    exclusive: [
      { race: :race_unknown, label: 'UNKNOWN' },
      { race: :race_refused_to_answer, label: 'REFUSED TO ANSWER' }
    ]
  }.freeze

  TIME_OPTIONS = {
    Morning: 'Morning',
    Afternoon: 'Afternoon',
    Evening: 'Evening',
    '0': 'Midnight',
    '1': '01:00',
    '2': '02:00',
    '3': '03:00',
    '4': '04:00',
    '5': '05:00',
    '6': '06:00',
    '7': '07:00',
    '8': '08:00',
    '9': '09:00',
    '10': '10:00',
    '11': '11:00',
    '12': 'Noon',
    '13': '13:00',
    '14': '14:00',
    '15': '15:00',
    '16': '16:00',
    '17': '17:00',
    '18': '18:00',
    '19': '19:00',
    '20': '20:00',
    '21': '21:00',
    '22': '22:00',
    '23': '23:00'
  }.freeze

  NORMALIZED_INVERTED_TIME_OPTIONS = TIME_OPTIONS.invert.merge({ '0': '00:00', '12': '12:00' }.invert).transform_keys(&:downcase).freeze

  TELEPHONE_TYPES = ['Smartphone', 'Plain Cell', 'Landline', nil, ''].freeze

  # Validates if a given date value is between (inclusive) two dates.
  def validate_between_dates(record, attribute, earliest_date, latest_date)
    return if attribute.nil? || record.nil? || !record.has_attribute?(attribute)

    # Get the new value to validate
    value = record[attribute]
    return if value.nil?

    # Validate that the value acts like a Date and add error otherwise
    attribute_label = attribute&.to_s&.humanize&.titleize
    record.errors.add(attribute, "#{value} is not valid for the #{attribute_label} field. Must be a valid date.") && return unless value.acts_like?(:date)

    # Validate inclusivity of Date, and add error if not valid
    is_valid = value >= earliest_date && value <= latest_date
    return if is_valid

    err_message = "#{value} is not valid for the #{attribute_label} field. Must be a valid date between (inclusive) #{earliest_date} and #{latest_date}."
    record.errors.add(attribute, err_message)
  end

  # Format validation errors from the model to be more human-readable
  # def format_model_validation_errors(resource)
  #   resource.errors&.messages&.each_with_object([]) do |(attribute, errors), messages|
  #     next unless VALIDATION.key?(attribute) || attribute == :base

  #     # NOTE: If the value is a date, the typecast value may not correspond to original user input, so get value_before_type_cast
  #     unless attribute == :base
  #       value = VALIDATION.dig(attribute, :checks)&.include?(:date) ? resource.public_send("#{attribute}_before_type_cast") : resource[attribute]
  #       msg_header = (value ? "Value '#{value}' for " : '') + "'#{VALIDATION[attribute][:label]}'"
  #     end
  #     errors.each do |error_message|
  #       # Exclude the actual value in logging to avoid PII/PHI
  #       Rails.logger.info "Validation Error on: #{attribute}"
  #       messages << "#{msg_header} #{error_message}".strip
  #     end
  #   end
  # end
end
