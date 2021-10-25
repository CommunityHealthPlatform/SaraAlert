import React from 'react';
import { PropTypes } from 'prop-types';
import { Alert, Button, Card, Col, Form } from 'react-bootstrap';
import Select from 'react-select';
import { bootstrapSelectTheme, cursorPointerStyleLg } from '../../../packs/stylesheets/ReactSelectStyling';

import _ from 'lodash';
import * as yup from 'yup';
import moment from 'moment-timezone';

import DateInput from '../../util/DateInput';
import InfoTooltip from '../../util/InfoTooltip';
import { getLanguageData } from '../../../utils/Languages';

let workflow_options;

// the terms 'contact' and 'case' are used commonly in public health settings,
// so we want to include them here in the UI for clarity
let publicHealthTerms = {
  exposure: 'Exposure (contact)',
  isolation: 'Isolation (case)',
};

class MonitoringProgram extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      ...this.props,
      current: { ...this.props.currentState },
      errors: {},
      modified: {},
    };
    // workflow_options = props.available_workflows.map(wf => ({ value: wf.name, label: publicHealthTerms[`${wf.name}`] }));
  }

  handleMonitoringProgramChange = event => {
    let value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    let current = this.state.current;
    let modified = this.state.modified;
    event.persist();
    this.setState(
      {
        current: { ...current, patient: { ...current.patient, [event.target.id]: value } },
        modified: { ...modified, patient: { ...modified.patient, [event.target.id]: value } },
      },
      () => {
        this.props.setEnrollmentState({ ...this.state.modified });
      }
    );
  };

  handleWorkflowChange = event => {
    const value = event.value;
    const current = this.state.current;
    const modified = this.state.modified;
    const isIsolation = value === 'isolation';
    this.setState(
      {
        current: { ...current, isolation: isIsolation, patient: { ...current.patient, isolation: isIsolation } },
        modified: { ...modified, isolation: isIsolation, patient: { ...modified.patient, isolation: isIsolation } },
      },
      () => {
        this.props.setEnrollmentState({ ...this.state.modified });
      }
    );
  };
  // At the current moment, it is assumed that at least one of `isolation` and `exposure` will be an available workflow option.
  getWorkflowValue = () =>
    this.state.current.isolation ? workflow_options.find(wf => wf.value === 'isolation') : workflow_options.find(wf => wf.value === 'exposure');

  validate = callback => {
    schema
      .validate(this.state.current.patient, { abortEarly: false })
      .then(() => {
        // No validation issues? Invoke callback (move to next step)
        this.setState({ errors: {} }, () => {
          callback();
        });
      })
      .catch(err => {
        // Validation errors, update state to display to user
        if (err && err.inner) {
          let issues = {};
          for (var issue of err.inner) {
            issues[issue['path']] = issue['errors'];
          }
          this.setState({ errors: issues });
        }
      });
  };

  render() {
    return (
      <React.Fragment>
        <h1 className="sr-only">Monitoring Program</h1>
        <Card className="mx-2 card-square">
          <Card.Header className="h5">Monitoring Program</Card.Header>
          <Card.Body>
            <Form>
                <Form.Row>
                <Form.Group as={Col}>
                  <Form.Label htmlFor="monitoring-program-select" className="input-label">
                    MONITORING PROGRAM *
                  </Form.Label>
                  <Select
                    inputId="monitoring-program-select"
                    styles={cursorPointerStyleLg}
                    // value={this.getWorkflowValue()}
                    // options={workflow_options}
                    // onChange={e => this.handleWorkflowChange(e)}
                    placeholder=""
                    theme={theme => bootstrapSelectTheme(theme, 'lg')}
                  />
                </Form.Group>
              </Form.Row>
              <Form.Row>
                <Form.Group as={Col}>
                  <Form.Label htmlFor="workflow-select" className="input-label">
                    WORKFLOW *
                  </Form.Label>
                  <Select
                    inputId="workflow-select"
                    styles={cursorPointerStyleLg}
                    // value={this.getWorkflowValue()}
                    // options={workflow_options}
                    // onChange={e => this.handleWorkflowChange(e)}
                    placeholder=""
                    theme={theme => bootstrapSelectTheme(theme, 'lg')}
                  />
                </Form.Group>
              </Form.Row>
            </Form>
            {this.props.next && (
              <Button
                id="enrollment-next-button"
                variant="outline-primary"
                size="lg"
                className="float-right btn-square px-5"
                onClick={() => this.validate(this.props.next)}>
                Next
              </Button>
            )}
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

const schema = yup.object().shape({
  // first_name: yup.string().required('Please enter a First Name.').max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  // middle_name: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  // last_name: yup.string().required('Please enter a Last Name.').max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  // date_of_birth: yup
  //   .date('Date must correspond to the "mm/dd/yyyy" format.')
  //   .required('Please enter a Date of Birth.')
  //   .max(new Date(), 'Date can not be in the future.')
  //   .nullable(),
  // age: yup.number().nullable(),
  // sex: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  // white: yup.boolean().nullable(),
  // black_or_african_american: yup.boolean().nullable(),
  // american_indian_or_alaska_native: yup.boolean().nullable(),
  // asian: yup.boolean().nullable(),
  // native_hawaiian_or_other_pacific_islander: yup.boolean().nullable(),
  // ethnicity: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  // primary_language: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  // secondary_language: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  // interpretation_required: yup.boolean().nullable(),
  // nationality: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
  // user_defined_id: yup.string().max(200, 'Max length exceeded, please limit to 200 characters.').nullable(),
});

MonitoringProgram.propTypes = {
  currentState: PropTypes.object,
  race_options: PropTypes.object,
  next: PropTypes.func,
  setEnrollmentState: PropTypes.func,
  authenticity_token: PropTypes.string,
  available_workflows: PropTypes.array,
};

export default MonitoringProgram;
