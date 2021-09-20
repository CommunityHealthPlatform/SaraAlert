import React from 'react';
import { PropTypes } from 'prop-types';
import { Accordion, Button } from 'react-bootstrap';

import InfoTooltip from '../util/InfoTooltip';

class ModuleManager extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      // the list of other MPs (not including the active one)
      otherMonitoringProgramsAvailable: this.props.available_monitoring_programs.filter(x => x.label !== props.playbook_label),
    };
  }

  switchModule = mp => {
    // This is obviously a stub that will be changed in the future
    mp.name = 'covid_19';
    const url = `${window.BASE_PATH}/monitoring_program/${mp.name}/dashboard`;
    location.href = url;
  };

  render() {
    {
      /* Only render the module manager if there actually are other MPs available */
    }
    return this.state.otherMonitoringProgramsAvailable.length === 0 ? null : (
      <React.Fragment>
        <div className="mx-2 mb-3" style={{ backgroundColor: '#e9ecef96' }}>
          <Accordion>
            <div className="px-3 py-2" style={{ display: 'inline-block' }}>
              {`${this.props.playbook_label} Monitoring Module`}
              <InfoTooltip
                location="right"
                getCustomText={() => {
                  return (
                    <div>
                      You are currently in the module for monitoring {this.props.playbook_label}
                      <div>
                        Other modules that are available to you are:
                        {this.state.otherMonitoringProgramsAvailable.map(x => x.label).join(', ')}
                      </div>
                    </div>
                  );
                }}
              />
            </div>
            <Accordion.Toggle as={Button} variant="link" eventKey="0" className="float-right">
              Switch Module
            </Accordion.Toggle>
            <Accordion.Collapse eventKey="0">
              <div className="mm-disease-list">
                {this.state.otherMonitoringProgramsAvailable.map((x, i) => (
                  <div key={i} className="mm-disease-entry mb-3 px-3" onClick={() => this.switchModule(x)}>
                    <div className="px-3 py-2"> {`${x.label} Monitoring Program`} </div>
                  </div>
                ))}
              </div>
            </Accordion.Collapse>
          </Accordion>
        </div>
      </React.Fragment>
    );
  }
}

ModuleManager.propTypes = {
  playbook_label: PropTypes.string,
  playbook_options: PropTypes.array,
  available_monitoring_programs: PropTypes.array,
};

export default ModuleManager;
