import React from 'react';
import { PropTypes } from 'prop-types';
import { Card } from 'react-bootstrap';
import Patient from './Patient';
import Dependent from './household/Dependent';
import HeadOfHousehold from './household/HeadOfHousehold';
import Individual from './household/Individual';

class PatientPage extends React.Component {
  render() {
    return (
      <React.Fragment>
        <Card id="patient-page" className="mx-2 card-square">
          <Card.Header className="h5" id="patient-info-header">
            Monitoree Details {this.props.patient.user_defined_id ? `(ID: ${this.props.patient.user_defined_id})` : ''}{' '}
          </Card.Header>
          <Card.Body>
            <Patient
              current_user={this.props.current_user}
              jurisdiction_path={this.props.jurisdiction_path}
              jurisdiction_paths={this.props.jurisdiction_paths}
              details={{ ...this.props.patient, blocked_sms: this.props.blocked_sms }}
              collapse={this.props.can_modify_subject_status}
              edit_mode={false}
              follow_up_reasons={this.props.follow_up_reasons}
              other_household_members={this.props.other_household_members}
              display_follow_up_flag={this.props.current_user.role != 'enroller'}
              authenticity_token={this.props.authenticity_token}
            />
            <div className="household-info">
              {!this.props.patient.head_of_household && this.props?.other_household_members?.length > 0 && (
                <Dependent
                  patient={this.props.patient}
                  hoh={this.props.other_household_members.find(patient => patient.head_of_household)}
                  authenticity_token={this.props.authenticity_token}
                />
              )}
              {this.props.patient.head_of_household && (
                <HeadOfHousehold
                  patient={this.props.patient}
                  dependents={this.props.other_household_members}
                  can_add_group={this.props.can_add_group}
                  authenticity_token={this.props.authenticity_token}
                />
              )}
              {!this.props.patient.head_of_household && this.props?.other_household_members?.length === 0 && (
                <Individual patient={this.props.patient} can_add_group={this.props.can_add_group} authenticity_token={this.props.authenticity_token} />
              )}
            </div>
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

PatientPage.propTypes = {
  current_user: PropTypes.object,
  can_add_group: PropTypes.bool,
  can_modify_subject_status: PropTypes.bool,
  patient: PropTypes.object,
  other_household_members: PropTypes.array,
  authenticity_token: PropTypes.string,
  jurisdiction_path: PropTypes.string,
  jurisdiction_paths: PropTypes.object,
  blocked_sms: PropTypes.bool,
  follow_up_reasons: PropTypes.array,
};

export default PatientPage;
