import React from 'react';
import { PropTypes } from 'prop-types';
import _ from 'lodash';
import { Card, Button, Modal } from 'react-bootstrap';
import ReactTooltip from 'react-tooltip';

import Patient from '../../patient/Patient';

class Review extends React.Component {
  constructor(props) {
    super(props);
    this.state = { disabled: false, showGroupAddNotification: false };
  }

  submit = (event, groupMember) => {
    // Update state before submitting data so submit button disables when clicked to prevent multiple submissions.
    this.setState({ disabled: true }, () => {
      this.props.submit(event, groupMember, this.reenableButtons);
    });
  };

  reenableButtons = () => {
    this.setState({ disabled: false });
  };

  toggleGroupAddNotification = () => {
    let current = this.state.showGroupAddNotification;
    this.setState({
      showGroupAddNotification: !current,
    });
  };

  totalMonitoringPrograms = () => {
    return _.isEmpty(this.props.currentState.monitoring_infos) ? 0 : Object.keys(this.props.currentState.monitoring_infos).length;
  };

  createModal() {
    return (
      <Modal size="lg" show centered onHide={this.toggleGroupAddNotification}>
        <Modal.Header>
          <Modal.Title>Enroll Household Members</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>
            Household enrollment allows for the Head of Household to submit reports on behalf of other members of the household. The head of household is the
            first household member enrolled. By clicking “continue”, any additional household members who are added will have their daily reports submitted by
            the Head of Household.
          </p>
          <p>
            Any household members who wish to report on their own behalf should be enrolled separately and not be added using the “Finish and Add a Household
            Member” button. Select “Cancel” then “Finish” to return to the main enrollment screen.
          </p>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary btn-square" onClick={this.toggleGroupAddNotification}>
            Cancel
          </Button>
          <Button variant="primary btn-square" onClick={event => this.submit(event, true)}>
            Continue
          </Button>
        </Modal.Footer>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        <Card className="mx-2 card-square">
          <Card.Header as="h1" className="patient-card-header">
            Monitoree Review
          </Card.Header>
          <Card.Body>
            <Patient
              goto={this.props.goto}
              setMonitoringInfoIndex={this.props.setMonitoringInfoIndex}
              edit_mode={true}
              jurisdiction_paths={this.props.jurisdiction_paths}
              details={{ ...this.props.currentState.patient, blocked_sms: this.props.currentState.blocked_sms } || {}}
              monitoring_infos={this.props.currentState.monitoring_infos}
              available_monitoring_programs={this.props.available_monitoring_programs}
              authenticity_token={this.props.authenticity_token}
              workflow={this.props.workflow}
              headingLevel={2}
            />
            {this.props.submit && (
              <React.Fragment>
                <span data-for="enrollment-add-monitoring-program-btn" data-tip="">
                  <Button
                    variant="primary"
                    size="lg"
                    className="btn-square mb-4"
                    disabled={this.state.disabled || this.totalMonitoringPrograms() === this.props.available_monitoring_programs.length}
                    onClick={() => {
                      this.props.goto(3, true);
                      this.props.setMonitoringInfoIndex(null);
                    }}>
                    Add Monitoring Program
                  </Button>
                </span>
                {this.totalMonitoringPrograms() === this.props.available_monitoring_programs.length && (
                  <ReactTooltip id="enrollment-add-monitoring-program-btn" multiline={true} place="top" effect="solid" className="tooltip-container">
                    You have enrolled in all available Monitoring Programs
                  </ReactTooltip>
                )}
              </React.Fragment>
            )}
            {this.props.submit && (
              <Button
                variant="secondary"
                size="lg"
                className="float-right btn-square px-5"
                disabled={this.state.disabled}
                onClick={() => {
                  window.history.back();
                }}>
                Cancel
              </Button>
            )}
            {this.props.submit && (
              <React.Fragment>
                <span data-for="enrollment-finish-btn" data-tip="">
                  <Button
                    variant="primary"
                    size="lg"
                    className="float-right btn-square px-5 mr-4"
                    disabled={this.state.disabled || this.totalMonitoringPrograms() === 0}
                    onClick={this.submit}>
                    Finish
                  </Button>
                </span>
                {this.totalMonitoringPrograms() === 0 && (
                  <ReactTooltip id="enrollment-finish-btn" multiline={true} place="top" effect="solid" className="tooltip-container">
                    You must enroll in at least one Monitoring Program
                  </ReactTooltip>
                )}
              </React.Fragment>
            )}
            {/* {this.props.submit && this.props.currentState.patient.responder_id === this.props.currentState.patient.id && this.props.canAddGroup && (
              <Button
                variant="primary"
                size="lg"
                className="float-right btn-square px-5 mr-4"
                disabled={this.state.disabled || this.totalMonitoringPrograms() === 0}
                onClick={this.toggleGroupAddNotification}>
                Finish and Add a Household Member
              </Button>
            )} */}
          </Card.Body>
        </Card>
        {this.state.showGroupAddNotification && this.createModal()}
      </React.Fragment>
    );
  }
}

Review.propTypes = {
  currentState: PropTypes.object,
  previous: PropTypes.func,
  goto: PropTypes.func,
  submit: PropTypes.func,
  setMonitoringInfoIndex: PropTypes.func,
  canAddGroup: PropTypes.bool,
  jurisdiction_paths: PropTypes.object,
  authenticity_token: PropTypes.string,
  workflow: PropTypes.string,
  available_monitoring_programs: PropTypes.array,
};

export default Review;
