import React from 'react';
import { PropTypes } from 'prop-types';
import { Col, Form } from 'react-bootstrap';
import _ from 'lodash';
import InfoTooltip from '../../util/InfoTooltip';

class PublicHealthManagement extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      ...this.props,
      current: { ...this.props.currentState },
      modified: {},
      originalAssignedUser: props.currentState.monitoring_infos[props.activeMonitoringInfoIndex]?.assigned_user,
    };
  }

  componentDidUpdate() {
    const newProps = this.props.currentState.monitoring_infos;
    if (Object.keys(newProps).length !== Object.keys(this.state.current.monitoring_infos).length) {
      let current = this.state.current;
      let modified = this.state.modified;
      this.setState({
        current: { ...current, monitoring_infos: { ...newProps } },
        modified: { ...modified, monitoring_infos: { ...newProps } },
      });
    }
  }

  handleChange = event => {
    let field = event?.target?.id;
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let current = this.state.current;
    let modified = this.state.modified;
    let currentMonitoringInfo = current.monitoring_infos;
    currentMonitoringInfo[this.props.activeMonitoringInfoIndex][`${field}`] = value;
    let modifiedMonitoringInfo = modified.monitoring_infos;
    modifiedMonitoringInfo[this.props.activeMonitoringInfoIndex][`${field}`] = value;

    if (field && event.target.id === 'assigned_user') {
      if (isNaN(value) || parseInt(value) > 999999) return;

      // trim call included since there is a bug with yup validation for numbers that allows whitespace entry
      value = _.trim(value) === '' ? null : parseInt(value);
    }

    this.setState(
      {
        current: { ...current, monitoring_infos: currentMonitoringInfo },
        modified: { ...modified, monitoring_infos: modifiedMonitoringInfo },
      },
      () => {
        this.props.onChange(value, field);
      }
    );
  };

  render() {
    return (
      <React.Fragment>
        <Form.Row className="pt-2 g-border-bottom-2" />
        <Form.Row className="pt-2">
          <Form.Group as={Col} className="mb-2">
            <Form.Label className="input-label">PUBLIC HEALTH RISK ASSESSMENT AND MANAGEMENT</Form.Label>
          </Form.Group>
        </Form.Row>
        <Form.Row>
          <Form.Group as={Col} md={6} className="mb-2 pt-2" controlId="assigned_user">
            <Form.Label className="input-label">
              ASSIGNED USER{this.props.schema?.fields?.assigned_user?._exclusive?.required && ' *'}
              <InfoTooltip tooltipTextKey="assignedUser" location="top"></InfoTooltip>
            </Form.Label>
            <Form.Control
              isInvalid={this.props.errors['assigned_user']}
              as="input"
              list="assigned_users"
              autoComplete="off"
              size="lg"
              className="form-square"
              onChange={this.handleChange}
              value={this.state.current.monitoring_infos[this.props.activeMonitoringInfoIndex]?.assigned_user || ''}
            />
            <datalist id="assigned_users">
              {this.state.assigned_users?.map(num => {
                return (
                  <option value={num} key={num}>
                    {num}
                  </option>
                );
              })}
            </datalist>
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.props.errors['assigned_user']}
            </Form.Control.Feedback>
            {/* {this.props.has_dependents &&
              this.state.current.patient.assigned_user !== this.state.originalAssignedUser &&
              (this.state.current.patient.assigned_user === null ||
                (this.state.current.patient.assigned_user > 0 && this.state.current.patient.assigned_user <= 999999)) && (
                <Form.Group className="mt-2">
                  <Form.Check
                    type="switch"
                    id="update_group_member_assigned_user"
                    name="assigned_user"
                    label="Apply this change to the entire household that this monitoree is responsible for"
                    onChange={this.props.onPropagatedFieldChange}
                    checked={this.props.currentState.propagatedFields.assigned_user || false}
                  />
                </Form.Group>
              )} */}
          </Form.Group>
          <Form.Group as={Col} md={6} controlId="exposure_risk_assessment" className="mb-2 pt-2">
            <Form.Label className="input-label">RISK ASSESSMENT{this.props.schema?.fields?.exposure_risk_assessment?._exclusive?.required && ' *'}</Form.Label>
            <Form.Control
              isInvalid={this.props.errors['exposure_risk_assessment']}
              as="select"
              size="lg"
              className="form-square"
              onChange={this.handleChange}
              value={this.state.current.monitoring_infos[this.props.activeMonitoringInfoIndex]?.exposure_risk_assessment || ''}>
              <option></option>
              <option>High</option>
              <option>Medium</option>
              <option>Low</option>
              <option>No Identified Risk</option>
            </Form.Control>
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.props.errors['exposure_risk_assessment']}
            </Form.Control.Feedback>
          </Form.Group>
          <Form.Group as={Col} md={12} controlId="monitoring_plan" className="mb-2 pt-2">
            <Form.Label className="input-label">MONITORING PLAN{this.props.schema?.fields?.monitoring_plan?._exclusive?.required && ' *'}</Form.Label>
            <Form.Control
              isInvalid={this.props.errors['monitoring_plan']}
              as="select"
              size="lg"
              className="form-square"
              onChange={this.handleChange}
              value={this.state.current.monitoring_infos[this.props.activeMonitoringInfoIndex]?.monitoring_plan || ''}>
              <option></option>
              <option>None</option>
              <option>Daily active monitoring</option>
              <option>Self-monitoring with public health supervision</option>
              <option>Self-monitoring with delegated supervision</option>
              <option>Self-observation</option>
            </Form.Control>
            <Form.Control.Feedback className="d-block" type="invalid">
              {this.props.errors['monitoring_plan']}
            </Form.Control.Feedback>
          </Form.Group>
        </Form.Row>
      </React.Fragment>
    );
  }
}

PublicHealthManagement.propTypes = {
  activeMonitoringInfoIndex: PropTypes.number,
  currentState: PropTypes.object,
  onChange: PropTypes.func,
  onPropagatedFieldChange: PropTypes.func,
  has_dependents: PropTypes.bool,
  assigned_users: PropTypes.array,
  schema: PropTypes.object,
  errors: PropTypes.object,
};

export default PublicHealthManagement;
