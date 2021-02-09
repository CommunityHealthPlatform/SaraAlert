import { mockNote } from './mockNote'

const blankMockPatient = {
  additional_planned_travel_destination: null,
  additional_planned_travel_destination_country: null,
  additional_planned_travel_destination_state: null,
  additional_planned_travel_end_date: null,
  additional_planned_travel_port_of_departure: null,
  additional_planned_travel_related_notes: null,
  additional_planned_travel_start_date: null,
  additional_planned_travel_type: null,
  address_city: null,
  address_county: null,
  address_line_1: null,
  address_line_2: null,
  address_state: null,
  address_zip: null,
  age: 0,
  american_indian_or_alaska_native: null,
  asian: true,
  assigned_user: 0,
  black_or_african_american: null,
  case_status: null,
  closed_at: null,
  contact_of_known_case: false,
  contact_of_known_case_id: null,
  continuous_exposure: false,
  created_at: null,
  creator_id: 0,
  crew_on_passenger_or_cargo_flight: false,
  date_of_arrival: null,
  date_of_birth: null,
  date_of_departure: null,
  email: null,
  ethnicity: null,
  exposure_notes: null,
  exposure_risk_assessment: null,
  extended_isolation: null,
  first_name: null,
  flight_or_vessel_carrier: null,
  flight_or_vessel_number: null,
  foreign_address_city: null,
  foreign_address_country: null,
  foreign_address_line_1: null,
  foreign_address_line_2: null,
  foreign_address_line_3: null,
  foreign_address_state: null,
  foreign_address_zip: null,
  foreign_monitored_address_city: null,
  foreign_monitored_address_county: null,
  foreign_monitored_address_line_1: null,
  foreign_monitored_address_line_2: null,
  foreign_monitored_address_state: null,
  foreign_monitored_address_zip: null,
  gender_identity: null,
  healthcare_personnel: null,
  healthcare_personnel_facility_name: null,
  id: 0,
  interpretation_required: true,
  isolation: true,
  jurisdiction_id: 0,
  laboratory_personnel: false,
  laboratory_personnel_facility_name: null,
  last_assessment_reminder_sent: null,
  last_date_of_exposure: null,
  last_name: null,
  latest_assessment_at: null,
  latest_fever_or_fever_reducer_at: null,
  latest_positive_lab_at: null,
  latest_transfer_at: null,
  latest_transfer_from: null,
  linelist: {
    assigned_user: 0,
    closed_at: null,
    dob: null,
    end_of_monitoring: null,
    expected_purge_date: null,
    extended_isolation: null,
    id: 0,
    jurisdiction: null,
    latest_report: null,
    monitoring_plan: null,
    name: null,
    public_health_action: null,
    reason_for_closure: null,
    risk_level: null,
    sex: null,
    state_local_id: null,
    status: null,
    transferred_at: null,
    transferred_from: null,
    transferred_to: null,
  },
  member_of_a_common_exposure_cohort: null,
  member_of_a_common_exposure_cohort_type: null,
  middle_name: null,
  monitored_address_city: null,
  monitored_address_county: null,
  monitored_address_line_1: null,
  monitored_address_line_2: null,
  monitored_address_state: null,
  monitored_address_zip: null,
  monitoring: true,
  monitoring_plan: null,
  monitoring_reason: null,
  nationality: null,
  native_hawaiian_or_other_pacific_islander: null,
  negative_lab_count: 0,
  pause_notifications: false,
  port_of_entry_into_usa: null,
  port_of_origin: null,
  potential_exposure_country: null,
  potential_exposure_location: null,
  preferred_contact_method: null,
  preferred_contact_time: null,
  primary_language: null,
  primary_telephone: null,
  primary_telephone_type: null,
  public_health_action: null,
  purged: false,
  responder_id: 0,
  secondary_language: null,
  secondary_telephone: null,
  secondary_telephone_type: null,
  sex: null,
  sexual_orientation: null,
  source_of_report: null,
  source_of_report_specify: null,
  submission_token: null,
  symptom_onset: null,
  travel_related_notes: null,
  travel_to_affected_country_or_area: false,
  updated_at: null,
  user_defined_id: null,
  user_defined_id_cdc: null,
  user_defined_id_nndss: null,
  user_defined_id_statelocal: null,
  user_defined_symptom_onset: null,
  was_in_health_care_facility_with_known_cases: false,
  was_in_health_care_facility_with_known_cases_facility_name: null,
  white: null
}

const mockPatient1 = {
  additional_planned_travel_destination: 'Kokomo',
  additional_planned_travel_destination_country: 'USA',
  additional_planned_travel_destination_state: 'Florida',
  additional_planned_travel_end_date: '2020-09-16',
  additional_planned_travel_port_of_departure: 'Miami',
  additional_planned_travel_related_notes: 'some additional planned travel related note here',
  additional_planned_travel_start_date: '2020-09-05',
  additional_planned_travel_type: 'Domestic',
  address_city: 'Springfield',
  address_county: 'Fairfield',
  address_line_1: '1 Hartford Drive',
  address_line_2: null,
  address_state: 'Connecticut',
  address_zip: '00000-0000',
  age: 76,
  american_indian_or_alaska_native: null,
  asian: true,
  assigned_user: 21,
  black_or_african_american: null,
  case_status: 'Suspect',
  closed_at: '2020-09-13T20:32:02.000Z',
  contact_of_known_case: false,
  contact_of_known_case_id: null,
  continuous_exposure: false,
  created_at: '2020-09-13T14:35:09.000Z',
  creator_id: 4,
  crew_on_passenger_or_cargo_flight: false,
  date_of_arrival: '2020-09-10',
  date_of_birth: '1945-03-08',
  date_of_departure: '2020-09-08',
  email: 'minnie.mouse@example.com',
  ethnicity: 'Not Hispanic or Latino',
  exposure_notes: 'some exposure notes here',
  exposure_risk_assessment: 'No Identified Risk',
  extended_isolation: null,
  first_name: 'Minnie',
  flight_or_vessel_carrier: 'Spirit',
  flight_or_vessel_number: '1515',
  foreign_address_city: null,
  foreign_address_country: null,
  foreign_address_line_1: null,
  foreign_address_line_2: null,
  foreign_address_line_3: null,
  foreign_address_state: null,
  foreign_address_zip: null,
  foreign_monitored_address_city: null,
  foreign_monitored_address_county: null,
  foreign_monitored_address_line_1: null,
  foreign_monitored_address_line_2: null,
  foreign_monitored_address_state: null,
  foreign_monitored_address_zip: null,
  gender_identity: 'Female (Identifies as female)',
  healthcare_personnel: true,
  healthcare_personnel_facility_name: 'Crystal Ball',
  id: 17,
  interpretation_required: true,
  isolation: true,
  jurisdiction_id: 4,
  laboratory_personnel: false,
  laboratory_personnel_facility_name: null,
  last_assessment_reminder_sent: null,
  last_date_of_exposure: '2020-09-13',
  last_name: 'Mouse',
  latest_assessment_at: '2020-09-15T20:59:36.000Z',
  latest_fever_or_fever_reducer_at: null,
  latest_positive_lab_at: null,
  latest_transfer_at: null,
  latest_transfer_from: null,
  linelist: {
    assigned_user: 21,
    closed_at: 'Sun, 13 Sep 2020 20:32:02 +0000',
    dob: '1945-03-08',
    end_of_monitoring: '2020-09-27',
    expected_purge_date: 'Sun, 27 Sep 2020 20:32:02 +0000',
    extended_isolation: '',
    id: 17,
    jurisdiction: 'County 2',
    latest_report: 'Tue, 15 Sep 2020 20:59:36 +0000',
    monitoring_plan: 'None',
    name: 'Mouse, Minnie',
    public_health_action: 'None',
    reason_for_closure: 'Transferred to another jurisdiction',
    risk_level: 'No Identified Risk',
    sex: 'Female',
    state_local_id: 'EX-771721',
    status: 'reporting',
    transferred_at: '',
    transferred_from: '',
    transferred_to: ''
  },
  member_of_a_common_exposure_cohort: true,
  member_of_a_common_exposure_cohort_type: 'Dark Two-Face',
  middle_name: 'M',
  monitored_address_city: 'Santoton',
  monitored_address_county: 'Pine Heights',
  monitored_address_line_1: '94011 Green Passage',
  monitored_address_line_2: 'Suite 455',
  monitored_address_state: 'Massachusetts',
  monitored_address_zip: '98145-4774',
  monitoring: true,
  monitoring_plan: 'Daily active monitoring',
  monitoring_reason: 'Transferred to another jurisdiction',
  nationality: 'Serbs',
  native_hawaiian_or_other_pacific_islander: null,
  negative_lab_count: 0,
  pause_notifications: false,
  port_of_entry_into_usa: 'Orlando',
  port_of_origin: 'Cabo',
  potential_exposure_country: 'Mexico',
  potential_exposure_location: null,
  preferred_contact_method: 'E-mailed Web Link',
  preferred_contact_time: null,
  primary_language: 'English',
  primary_telephone: null,
  primary_telephone_type: null,
  public_health_action: 'None',
  purged: false,
  responder_id: 17,
  secondary_language: null,
  secondary_telephone: null,
  secondary_telephone_type: null,
  sex: 'Female',
  sexual_orientation: 'Straight or Heterosexual',
  source_of_report: null,
  source_of_report_specify: null,
  submission_token: 'ed3535055837367e9edb14b131b130b5f4c70e15',
  symptom_onset: '2020-09-27',
  travel_related_notes: 'some travel related note here',
  travel_to_affected_country_or_area: false,
  updated_at: '2020-09-13T20:32:02.000Z',
  user_defined_id_cdc: '4677015425',
  user_defined_id_nndss: '38966610-6',
  user_defined_id_statelocal: 'EX-771721',
  user_defined_symptom_onset: null,
  was_in_health_care_facility_with_known_cases: false,
  was_in_health_care_facility_with_known_cases_facility_name: null,
  white: null
}

const mockPatient2 = {
  additional_planned_travel_destination: 'Kokomo',
  additional_planned_travel_destination_country: 'USA',
  additional_planned_travel_destination_state: 'Florida',
  additional_planned_travel_end_date: '2020-09-16',
  additional_planned_travel_port_of_departure: 'Miami',
  additional_planned_travel_related_notes: null,
  additional_planned_travel_start_date: '2020-09-05',
  additional_planned_travel_type: 'Domestic',
  address_city: 'Springfield',
  address_county: 'Fairfield',
  address_line_1: '1 Hartford Drive',
  address_line_2: null,
  address_state: 'Connecticut',
  address_zip: '00000-0000',
  age: 79,
  american_indian_or_alaska_native: null,
  asian: true,
  assigned_user: 21,
  black_or_african_american: null,
  case_status: 'Confirmed',
  closed_at: '2020-09-13T20:32:02.000Z',
  contact_of_known_case: true,
  contact_of_known_case_id: '1000',
  continuous_exposure: false,
  created_at: '2020-09-13T14:35:09.000Z',
  creator_id: 4,
  crew_on_passenger_or_cargo_flight: true,
  date_of_arrival: null,
  date_of_birth: '1942-03-08',
  date_of_departure: null,
  email: 'mickey.mouse@example.com',
  ethnicity: 'Not Hispanic or Latino',
  exposure_notes: 'hi this is a note',
  exposure_risk_assessment: 'No Identified Risk',
  extended_isolation: null,
  first_name: 'Mickey',
  flight_or_vessel_carrier: null,
  flight_or_vessel_number: null,
  foreign_address_city: null,
  foreign_address_country: null,
  foreign_address_line_1: null,
  foreign_address_line_2: null,
  foreign_address_line_3: null,
  foreign_address_state: null,
  foreign_address_zip: null,
  foreign_monitored_address_city: null,
  foreign_monitored_address_county: null,
  foreign_monitored_address_line_1: null,
  foreign_monitored_address_line_2: null,
  foreign_monitored_address_state: null,
  foreign_monitored_address_zip: null,
  gender_identity: null,
  healthcare_personnel: true,
  healthcare_personnel_facility_name: 'Crystal Ball',
  id: 18,
  interpretation_required: true,
  isolation: false,
  jurisdiction_id: 4,
  laboratory_personnel: true,
  laboratory_personnel_facility_name: 'Space Mountain',
  last_assessment_reminder_sent: null,
  last_date_of_exposure: '2020-09-13',
  last_name: 'Mouse',
  latest_assessment_at: '2020-09-15T20:59:36.000Z',
  latest_fever_or_fever_reducer_at: null,
  latest_positive_lab_at: null,
  latest_transfer_at: null,
  latest_transfer_from: null,
  linelist: {
    assigned_user: 21,
    closed_at: 'Sun, 13 Sep 2020 20:32:02 +0000',
    dob: '1942-03-08',
    end_of_monitoring: '2020-09-27',
    expected_purge_date: 'Sun, 27 Sep 2020 20:32:02 +0000',
    extended_isolation: '',
    id: 18,
    jurisdiction: 'County 2',
    latest_report: 'Tue, 15 Sep 2020 20:59:36 +0000',
    monitoring_plan: 'None',
    name: 'Mouse, Mickey',
    public_health_action: 'None',
    reason_for_closure: 'Transferred to another jurisdiction',
    risk_level: 'No Identified Risk',
    sex: 'Male',
    state_local_id: 'EX-771721',
    status: 'reporting',
    transferred_at: '',
    transferred_from: '',
    transferred_to: ''
  },
  member_of_a_common_exposure_cohort: true,
  member_of_a_common_exposure_cohort_type: 'Dark Two-Face',
  middle_name: 'M',
  monitored_address_city: null,
  monitored_address_county: null,
  monitored_address_line_1: null,
  monitored_address_line_2: null,
  monitored_address_state: null,
  monitored_address_zip: null,
  monitoring: true,
  monitoring_plan: 'None',
  monitoring_reason: null,
  nationality: 'Serbs',
  native_hawaiian_or_other_pacific_islander: null,
  negative_lab_count: 0,
  pause_notifications: false,
  port_of_entry_into_usa: null,
  port_of_origin: null,
  potential_exposure_country: 'Mexico',
  potential_exposure_location: 'Tulum',
  preferred_contact_method: 'SMS Texted Weblink',
  preferred_contact_time: null,
  primary_language: 'English',
  primary_telephone: '123-456-7890',
  primary_telephone_type: 'Smartphone',
  public_health_action: 'None',
  purged: false,
  responder_id: 17,
  secondary_language: null,
  secondary_telephone: null,
  secondary_telephone_type: null,
  sex: 'Male',
  sexual_orientation: null,
  source_of_report: null,
  source_of_report_specify: null,
  submission_token: 'ed3535055837367e9edb14b131b130b5f4c70e15',
  symptom_onset: null,
  travel_related_notes: null,
  travel_to_affected_country_or_area: true,
  updated_at: '2020-09-13T20:32:02.000Z',
  user_defined_id: '00000-1',
  user_defined_id_cdc: '4677015425',
  user_defined_id_nndss: '38966610-6',
  user_defined_id_statelocal: 'EX-771721',
  user_defined_symptom_onset: null,
  was_in_health_care_facility_with_known_cases: true,
  was_in_health_care_facility_with_known_cases_facility_name: 'ABC Care',
  white: null
}

const mockPatient3 = {
  additional_planned_travel_destination: 'Kokomo',
  additional_planned_travel_destination_country: 'USA',
  additional_planned_travel_destination_state: 'Florida',
  additional_planned_travel_end_date: '2020-09-16',
  additional_planned_travel_port_of_departure: 'Miami',
  additional_planned_travel_related_notes: mockNote,
  additional_planned_travel_start_date: '2020-09-05',
  additional_planned_travel_type: 'Domestic',
  address_city: 'Springfield',
  address_county: 'Fairfield',
  address_line_1: '1 Hartford Drive',
  address_line_2: null,
  address_state: 'Connecticut',
  address_zip: '00000-0000',
  age: 56,
  american_indian_or_alaska_native: null,
  asian: true,
  assigned_user: 21,
  black_or_african_american: null,
  case_status: 'Unknown',
  closed_at: '2020-09-13T20:32:02.000Z',
  contact_of_known_case: true,
  contact_of_known_case_id: '1000',
  continuous_exposure: false,
  created_at: '2020-09-13T14:35:09.000Z',
  creator_id: 4,
  crew_on_passenger_or_cargo_flight: true,
  date_of_arrival: null,
  date_of_birth: '1964-05-20',
  date_of_departure: null,
  email: 'donaldduck222@example.com',
  ethnicity: 'Not Hispanic or Latino',
  exposure_notes: mockNote,
  exposure_risk_assessment: 'No Identified Risk',
  extended_isolation: null,
  first_name: 'Donald',
  flight_or_vessel_carrier: null,
  flight_or_vessel_number: null,
  foreign_address_city: null,
  foreign_address_country: null,
  foreign_address_line_1: null,
  foreign_address_line_2: null,
  foreign_address_line_3: null,
  foreign_address_state: null,
  foreign_address_zip: null,
  foreign_monitored_address_city: null,
  foreign_monitored_address_county: null,
  foreign_monitored_address_line_1: null,
  foreign_monitored_address_line_2: null,
  foreign_monitored_address_state: null,
  foreign_monitored_address_zip: null,
  gender_identity: null,
  healthcare_personnel: true,
  healthcare_personnel_facility_name: 'Crystal Ball',
  id: 56,
  interpretation_required: true,
  isolation: false,
  jurisdiction_id: 4,
  laboratory_personnel: true,
  laboratory_personnel_facility_name: 'Space Mountain',
  last_assessment_reminder_sent: null,
  last_date_of_exposure: '2020-09-13',
  last_name: 'Duck',
  latest_assessment_at: '2020-09-15T20:59:36.000Z',
  latest_fever_or_fever_reducer_at: null,
  latest_positive_lab_at: null,
  latest_transfer_at: null,
  latest_transfer_from: null,
  linelist: {
    assigned_user: 21,
    closed_at: 'Sun, 13 Sep 2020 20:32:02 +0000',
    dob: '1964-05-20',
    end_of_monitoring: '2020-09-27',
    expected_purge_date: 'Sun, 27 Sep 2020 20:32:02 +0000',
    extended_isolation: '',
    id: 56,
    jurisdiction: 'County 2',
    latest_report: 'Tue, 15 Sep 2020 20:59:36 +0000',
    monitoring_plan: 'None',
    name: 'Duck, Donald',
    public_health_action: 'None',
    reason_for_closure: 'Transferred to another jurisdiction',
    risk_level: 'No Identified Risk',
    sex: 'Male',
    state_local_id: 'EX-771721',
    status: 'reporting',
    transferred_at: '',
    transferred_from: '',
    transferred_to: ''
  },
  member_of_a_common_exposure_cohort: true,
  member_of_a_common_exposure_cohort_type: 'Dark Two-Face',
  middle_name: 'M',
  monitored_address_city: 'Santoton',
  monitored_address_county: 'Pine Heights',
  monitored_address_line_1: '94011 Green Passage',
  monitored_address_line_2: 'Suite 455',
  monitored_address_state: 'Massachusetts',
  monitored_address_zip: '98145-4774',
  monitoring: false,
  monitoring_plan: 'None',
  monitoring_reason: null,
  nationality: 'Serbs',
  native_hawaiian_or_other_pacific_islander: null,
  negative_lab_count: 0,
  pause_notifications: false,
  port_of_entry_into_usa: null,
  port_of_origin: null,
  potential_exposure_country: 'Mexico',
  potential_exposure_location: 'Tulum',
  preferred_contact_method: 'SMS Texted Weblink',
  preferred_contact_time: null,
  primary_language: 'English',
  primary_telephone: '123-456-7890',
  primary_telephone_type: 'Smartphone',
  public_health_action: 'None',
  purged: false,
  responder_id: 17,
  secondary_language: null,
  secondary_telephone: null,
  secondary_telephone_type: null,
  sex: 'Male',
  sexual_orientation: null,
  source_of_report: null,
  source_of_report_specify: null,
  submission_token: 'ed3535055837367e9edb14b131b130b5f4c70e15',
  symptom_onset: null,
  travel_related_notes: mockNote,
  travel_to_affected_country_or_area: true,
  updated_at: '2020-09-13T20:32:02.000Z',
  user_defined_id: '00000-1',
  user_defined_id_cdc: '4677015425',
  user_defined_id_nndss: '38966610-6',
  user_defined_id_statelocal: 'EX-771721',
  user_defined_symptom_onset: null,
  was_in_health_care_facility_with_known_cases: true,
  was_in_health_care_facility_with_known_cases_facility_name: 'ABC Care',
  white: null
}

const mockPatient4 = {
  additional_planned_travel_destination: 'Kokomo',
  additional_planned_travel_destination_country: 'USA',
  additional_planned_travel_destination_state: 'Florida',
  additional_planned_travel_end_date: '2020-09-16',
  additional_planned_travel_port_of_departure: 'Miami',
  additional_planned_travel_related_notes: null,
  additional_planned_travel_start_date: '2020-09-05',
  additional_planned_travel_type: 'Domestic',
  address_city: null,
  address_county: null,
  address_line_1: null,
  address_line_2: null,
  address_state: null,
  address_zip: null,
  age: 27,
  american_indian_or_alaska_native: null,
  asian: true,
  assigned_user: 21,
  black_or_african_american: null,
  case_status: 'Probable',
  closed_at: '2020-09-13T20:32:02.000Z',
  contact_of_known_case: true,
  contact_of_known_case_id: '1000',
  continuous_exposure: false,
  created_at: '2020-09-13T14:35:09.000Z',
  creator_id: 4,
  crew_on_passenger_or_cargo_flight: true,
  date_of_arrival: null,
  date_of_birth: '1993-04-20',
  date_of_departure: null,
  email: 'goofus.d.dawg@example.com',
  ethnicity: 'Not Hispanic or Latino',
  exposure_notes: null,
  exposure_risk_assessment: 'No Identified Risk',
  extended_isolation: null,
  first_name: 'Goofy',
  flight_or_vessel_carrier: null,
  flight_or_vessel_number: null,
  foreign_address_city: 'Rome',
  foreign_address_country: 'Italy',
  foreign_address_line_1: '1 Caesar Via',
  foreign_address_line_2: null,
  foreign_address_line_3: null,
  foreign_address_state: null,
  foreign_address_zip: '98765-4321',
  foreign_monitored_address_city: 'Paris',
  foreign_monitored_address_county: 'France',
  foreign_monitored_address_line_1: '15 Baguette Lane',
  foreign_monitored_address_line_2: null,
  foreign_monitored_address_state: null,
  foreign_monitored_address_zip: 'X1500',
  gender_identity: null,
  healthcare_personnel: true,
  healthcare_personnel_facility_name: 'Crystal Ball',
  id: 69,
  interpretation_required: true,
  isolation: true,
  jurisdiction_id: 4,
  laboratory_personnel: true,
  laboratory_personnel_facility_name: 'Space Mountain',
  last_assessment_reminder_sent: null,
  last_date_of_exposure: '2020-09-13',
  last_name: 'Dawg',
  latest_assessment_at: '2020-09-15T20:59:36.000Z',
  latest_fever_or_fever_reducer_at: null,
  latest_positive_lab_at: null,
  latest_transfer_at: null,
  latest_transfer_from: null,
  linelist: {
    assigned_user: 21,
    closed_at: 'Sun, 13 Sep 2020 20:32:02 +0000',
    dob: '1993-04-20',
    end_of_monitoring: '2020-09-27',
    expected_purge_date: 'Sun, 27 Sep 2020 20:32:02 +0000',
    extended_isolation: '',
    id: 69,
    jurisdiction: 'County 2',
    latest_report: 'Tue, 15 Sep 2020 20:59:36 +0000',
    monitoring_plan: 'None',
    name: 'Dawg, Goofy',
    public_health_action: 'None',
    reason_for_closure: 'Transferred to another jurisdiction',
    risk_level: 'No Identified Risk',
    sex: 'Male',
    state_local_id: 'EX-771721',
    status: 'reporting',
    transferred_at: '',
    transferred_from: '',
    transferred_to: ''
  },
  member_of_a_common_exposure_cohort: true,
  member_of_a_common_exposure_cohort_type: 'Dark Two-Face',
  middle_name: 'M',
  monitored_address_city: null,
  monitored_address_county: null,
  monitored_address_line_1: null,
  monitored_address_line_2: null,
  monitored_address_state: null,
  monitored_address_zip: null,
  monitoring: true,
  monitoring_plan: 'None',
  monitoring_reason: null,
  nationality: 'canine',
  native_hawaiian_or_other_pacific_islander: null,
  negative_lab_count: 0,
  pause_notifications: true,
  port_of_entry_into_usa: null,
  port_of_origin: null,
  potential_exposure_country: 'Mexico',
  potential_exposure_location: 'Tulum',
  preferred_contact_method: 'SMS Texted Weblink',
  preferred_contact_time: null,
  primary_language: 'English',
  primary_telephone: '123-456-7890',
  primary_telephone_type: 'Smartphone',
  public_health_action: 'None',
  purged: false,
  responder_id: 69,
  secondary_language: null,
  secondary_telephone: null,
  secondary_telephone_type: null,
  sex: 'Male',
  sexual_orientation: null,
  source_of_report: null,
  source_of_report_specify: null,
  submission_token: 'ed3535055837367e9edb14b131b130b5f4c70e15',
  symptom_onset: null,
  travel_related_notes: null,
  travel_to_affected_country_or_area: true,
  updated_at: '2020-09-13T20:32:02.000Z',
  user_defined_id: '00000-1',
  user_defined_id_cdc: '4677015425',
  user_defined_id_nndss: '38966610-6',
  user_defined_id_statelocal: 'EX-771721',
  user_defined_symptom_onset: null,
  was_in_health_care_facility_with_known_cases: true,
  was_in_health_care_facility_with_known_cases_facility_name: 'ABC Care',
  white: null
}

const mockPatient5 = {
  additional_planned_travel_destination: 'Kokomo',
  additional_planned_travel_destination_country: 'USA',
  additional_planned_travel_destination_state: 'Florida',
  additional_planned_travel_end_date: '2020-09-16',
  additional_planned_travel_port_of_departure: 'Miami',
  additional_planned_travel_related_notes: null,
  additional_planned_travel_start_date: '2020-09-05',
  additional_planned_travel_type: 'Domestic',
  address_city: null,
  address_county: null,
  address_line_1: null,
  address_line_2: null,
  address_state: null,
  address_zip: null,
  age: 27,
  american_indian_or_alaska_native: null,
  asian: true,
  assigned_user: 21,
  black_or_african_american: null,
  case_status: null,
  closed_at: null,
  contact_of_known_case: null,
  contact_of_known_case_id: null,
  continuous_exposure: false,
  created_at: '2020-09-13T14:35:09.000Z',
  creator_id: 4,
  crew_on_passenger_or_cargo_flight: null,
  date_of_arrival: null,
  date_of_birth: '1994-04-20',
  date_of_departure: null,
  email: 'Pete.p.Dastardly@example.com',
  ethnicity: 'Not Hispanic or Latino',
  exposure_notes: mockNote,
  exposure_risk_assessment: 'No Identified Risk',
  extended_isolation: null,
  first_name: 'Pete',
  flight_or_vessel_carrier: null,
  flight_or_vessel_number: null,
  foreign_address_city: 'Rome',
  foreign_address_country: 'Italy',
  foreign_address_line_1: '1 Caesar Via',
  foreign_address_line_2: null,
  foreign_address_line_3: null,
  foreign_address_state: null,
  foreign_address_zip: '98765-4321',
  foreign_monitored_address_city: null,
  foreign_monitored_address_county: null,
  foreign_monitored_address_line_1: null,
  foreign_monitored_address_line_2: null,
  foreign_monitored_address_state: null,
  foreign_monitored_address_zip: null,
  gender_identity: null,
  healthcare_personnel: null,
  healthcare_personnel_facility_name: null,
  id: 85,
  interpretation_required: true,
  isolation: false,
  jurisdiction_id: 4,
  laboratory_personnel: null,
  laboratory_personnel_facility_name: null,
  last_assessment_reminder_sent: null,
  last_date_of_exposure: null,
  last_name: 'Dastardly',
  latest_assessment_at: '2020-09-18T20:59:36.000Z',
  latest_fever_or_fever_reducer_at: null,
  latest_positive_lab_at: null,
  latest_transfer_at: null,
  latest_transfer_from: null,
  linelist: {
    assigned_user: 21,
    closed_at: null,
    dob: '1993-05-20',
    end_of_monitoring: '2020-09-27',
    expected_purge_date: 'Sun, 27 Sep 2020 20:32:02 +0000',
    extended_isolation: '',
    id: 85,
    jurisdiction: 'County 2',
    latest_report: 'Fri, 18 Sep 2020 20:59:36 +0000',
    monitoring_plan: 'None',
    name: 'Dastardly, Pete',
    public_health_action: 'Recommended laboratory testing',
    reason_for_closure: null,
    risk_level: 'No Identified Risk',
    sex: 'Male',
    state_local_id: 'EX-771221',
    status: 'reporting',
    transferred_at: '',
    transferred_from: '',
    transferred_to: ''
  },
  member_of_a_common_exposure_cohort: null,
  member_of_a_common_exposure_cohort_type: null,
  middle_name: 'M',
  monitored_address_city: null,
  monitored_address_county: null,
  monitored_address_line_1: null,
  monitored_address_line_2: null,
  monitored_address_state: null,
  monitored_address_zip: null,
  monitoring: true,
  monitoring_plan: 'None',
  monitoring_reason: null,
  nationality: 'canine',
  native_hawaiian_or_other_pacific_islander: null,
  negative_lab_count: 0,
  pause_notifications: true,
  port_of_entry_into_usa: null,
  port_of_origin: null,
  potential_exposure_country: null,
  potential_exposure_location: null,
  preferred_contact_method: 'SMS Texted Weblink',
  preferred_contact_time: null,
  primary_language: 'English',
  primary_telephone: '123-456-7880',
  primary_telephone_type: 'Smartphone',
  public_health_action: 'Recommended laboratory testing',
  purged: false,
  responder_id: 85,
  secondary_language: null,
  secondary_telephone: null,
  secondary_telephone_type: null,
  sex: 'Male',
  sexual_orientation: null,
  source_of_report: null,
  source_of_report_specify: null,
  submission_token: 'ed3535055837367e9edb14b131b130b5f4c70e15',
  symptom_onset: null,
  travel_related_notes: null,
  travel_to_affected_country_or_area: null,
  updated_at: '2020-09-13T20:32:02.000Z',
  user_defined_id: '00000-1',
  user_defined_id_cdc: '4677015425',
  user_defined_id_nndss: '38966610-6',
  user_defined_id_statelocal: 'EX-771721',
  user_defined_symptom_onset: null,
  was_in_health_care_facility_with_known_cases: null,
  was_in_health_care_facility_with_known_cases_facility_name: null,
  white: null
  }

export {
  blankMockPatient,
  mockPatient1,
  mockPatient2,
  mockPatient3,
  mockPatient4,
  mockPatient5
};