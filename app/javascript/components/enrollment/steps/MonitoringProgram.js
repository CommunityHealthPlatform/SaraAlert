import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, Card, Col, Form } from 'react-bootstrap';
import _ from 'lodash';
import ReactTooltip from 'react-tooltip';
import Select from 'react-select';
import { bootstrapSelectTheme, cursorPointerStyleLg } from '../../../packs/stylesheets/ReactSelectStyling';

// the terms 'contact' and 'case' are used commonly in public health settings,
// so we want to include them here in the UI for clarity
let publicHealthTerms = {
  exposure: 'Exposure (contact)',
  isolation: 'Isolation (case)',
};
let monitoring_program_options;
let workflow_options;

class MonitoringProgram extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      ...this.props,
      current: { ...this.props.currentState },
      modified: {},
      monitoringProgram: null,
      isolation: false,
    };
    monitoring_program_options = props.available_monitoring_programs.map(mp => ({ value: mp.id, label: mp.label }));
    workflow_options = props.available_workflows.map(wf => ({ value: wf.name, label: publicHealthTerms[`${wf.name}`] }));
  }

  handleMonitoringProgramChange = event => {
    let value = event.value;
    this.props.setMonitoringInfoIndex(value);
  };

  formatMonitoringProgramOptions = () => {
    return monitoring_program_options.map(mp => ({
      value: mp.value,
      label: mp.label,
      isDisabled: _.has(this.props.currentState.monitoring_infos, mp.value),
    }));
  };

  getMonitoringProgramValue = index => monitoring_program_options.find(mp => mp.value === index) || null;

  handleWorkflowChange = event => {
    const value = event.value;
    this.setState({ isolation: value === 'isolation' });
  };

  // At the current moment, it is assumed that at least one of `isolation` and `exposure` will be an available workflow option.
  getWorkflowValue = () =>
    this.state.isolation ? workflow_options.find(wf => wf.value === 'isolation') : workflow_options.find(wf => wf.value === 'exposure');

  addMonitoringProgram = callback => {
    const current = this.state.current;
    const modified = this.state.modified;
    this.setState(
      {
        current: { ...current, monitoring_infos: { ...current.monitoring_infos, [this.props.activeMonitoringInfoIndex]: { isolation: this.state.isolation } } },
        modified: {
          ...modified,
          monitoring_infos: { ...modified.monitoring_infos, [this.props.activeMonitoringInfoIndex]: { isolation: this.state.isolation } },
        },
      },
      () => {
        this.props.setEnrollmentState({ ...this.state.modified });
        callback();
      }
    );
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
                    value={this.getMonitoringProgramValue(this.props.activeMonitoringInfoIndex)}
                    options={this.formatMonitoringProgramOptions()}
                    onChange={e => this.handleMonitoringProgramChange(e)}
                    placeholder=""
                    theme={theme => bootstrapSelectTheme(theme, 'lg')}
                    menuPortalTarget={document.body}
                    styles={{ ...cursorPointerStyleLg, menuPortal: base => ({ ...base, zIndex: 9999 }) }}
                  />
                </Form.Group>
              </Form.Row>
              {this.props.activeMonitoringInfoIndex && (
                <Form.Row>
                  <Form.Group as={Col}>
                    <Form.Label htmlFor="workflow-select" className="input-label">
                      WORKFLOW *
                    </Form.Label>
                    <Select
                      inputId="workflow-select"
                      value={this.getWorkflowValue()}
                      options={workflow_options}
                      onChange={e => this.handleWorkflowChange(e)}
                      placeholder=""
                      theme={theme => bootstrapSelectTheme(theme, 'lg')}
                      menuPortalTarget={document.body}
                      styles={{ ...cursorPointerStyleLg, menuPortal: base => ({ ...base, zIndex: 9999 }) }}
                    />
                  </Form.Group>
                </Form.Row>
              )}
            </Form>
            {this.props.next && (
              <React.Fragment>
                <span data-for="monitoring-program-select-btn" data-tip="">
                  <Button
                    id="enrollment-next-button"
                    variant="outline-primary"
                    size="lg"
                    className="float-right btn-square px-5"
                    disabled={_.isNil(this.props.activeMonitoringInfoIndex)}
                    onClick={() => this.addMonitoringProgram(this.props.next)}>
                    Next
                  </Button>
                </span>
                {_.isNil(this.props.activeMonitoringInfoIndex) && (
                  <ReactTooltip id="monitoring-program-select-btn" multiline={true} place="left" effect="solid" className="tooltip-container">
                    Select a Monitoring Program before continuing
                  </ReactTooltip>
                )}
              </React.Fragment>
            )}
          </Card.Body>
        </Card>
      </React.Fragment>
    );
  }
}

MonitoringProgram.propTypes = {
  currentState: PropTypes.object,
  race_options: PropTypes.object,
  next: PropTypes.func,
  setEnrollmentState: PropTypes.func,
  setMonitoringInfoIndex: PropTypes.func,
  activeMonitoringInfoIndex: PropTypes.number,
  authenticity_token: PropTypes.string,
  available_workflows: PropTypes.array,
  available_monitoring_programs: PropTypes.array,
};

export default MonitoringProgram;
