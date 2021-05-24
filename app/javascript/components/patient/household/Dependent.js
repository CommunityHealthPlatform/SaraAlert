import React from 'react';
import { PropTypes } from 'prop-types';
import { Row } from 'react-bootstrap';
import BadgeHoH from './utils/BadgeHoH';
import HouseholdMemberTable from './utils/HouseholdMemberTable';
import RemoveFromHousehold from './actions/RemoveFromHousehold';
import { formatName } from '../../../utils/Patient';

class Dependent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      hoh: props.other_household_members.find(patient => patient.head_of_household),
    };
  }

  render() {
    return (
      <div id="household-member-not-hoh">
        <Row>This monitoree is a member of the following household:</Row>
        <Row className="pt-2">
          <HouseholdMemberTable
            household_members={this.props.other_household_members}
            current_user={this.props.current_user}
            jurisdiction_paths={this.props.jurisdiction_paths}
            isSelectable={false}
          />
        </Row>
        <Row>
          <RemoveFromHousehold patient={this.props.patient} authenticity_token={this.props.authenticity_token} />
        </Row>
      </div>
    );
  }
}

Dependent.propTypes = {
  patient: PropTypes.object,
  other_household_members: PropTypes.array,
  current_user: PropTypes.object,
  jurisdiction_paths: PropTypes.object,
  authenticity_token: PropTypes.string,
};

export default Dependent;
