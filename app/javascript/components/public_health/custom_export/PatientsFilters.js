import React from 'react';
import { PropTypes } from 'prop-types';
import { Col, Form, InputGroup, OverlayTrigger, Row, Tooltip } from 'react-bootstrap';

import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import axios from 'axios';

import AdvancedFilter from '../query/AdvancedFilter';
import AssignedUserFilter from '../query/AssignedUserFilter';
import JurisdictionFilter from '../query/JurisdictionFilter';

class PatientsFilters extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      assigned_users: [],
    };
  }

  componentDidMount() {
    this.updateAssignedUsers();
  }

  // Update Assigned Users datalist
  updateAssignedUsers = () => {
    axios
      .post(`${window.BASE_PATH}/jurisdictions/assigned_users`, {
        query: {
          jurisdiction: this.props.query?.jurisdiction || this.props.jurisdiction?.id,
          scope: this.props.query?.scope || 'all',
          workflow: this.props.query?.workflow,
          tab: this.props.query?.tab || 'all',
        },
      })
      .then(response => {
        this.setState({ assigned_users: response?.data?.assigned_users });
      });
  };

  render() {
    return (
      <Form.Group className="mb-0">
        <Row className="px-3">
          <Col md={12} className="my-1 px-1">
            <InputGroup size="sm" className="d-flex justify-content-between">
              <InputGroup.Prepend>
                <InputGroup.Text className="rounded-0">
                  <FontAwesomeIcon icon="project-diagram" />
                  <label htmlFor="workflow-filter" className="ml-1 mb-0">
                    Workflow
                  </label>
                </InputGroup.Text>
              </InputGroup.Prepend>
              <Form.Control
                id="workflow-filter"
                as="select"
                size="sm"
                className="form-square"
                onChange={event => {
                  this.props.onQueryChange('workflow', event?.target?.value);
                  this.props.onQueryChange('tab', 'all');
                }}
                value={this.props.query?.workflow}>
                {this.props.available_workflows.length > 1 && <option value="global">Global</option>}
                {this.props.available_workflows.map(wf => (
                  <option key={wf.name} value={wf.name}>
                    {' '}
                    {wf.label}{' '}
                  </option>
                ))}
              </Form.Control>
            </InputGroup>
          </Col>
          <Col md={12} className="my-1 px-1">
            <InputGroup size="sm" className="d-flex justify-content-between">
              <InputGroup.Prepend>
                <InputGroup.Text className="rounded-0">
                  <FontAwesomeIcon icon="stream" />
                  <label htmlFor="linelist-filter" className="ml-1 mb-0">
                    Line List
                  </label>
                </InputGroup.Text>
              </InputGroup.Prepend>
              <Form.Control
                id="linelist-filter"
                as="select"
                size="sm"
                className="form-square"
                onChange={event => this.props.onQueryChange('tab', event?.target?.value)}
                value={this.props.query?.tab}>
                {this.props.query?.workflow === 'global' && (
                  <React.Fragment>
                    <option value="active">Active</option>
                    <option value="priority_review">Priority Review</option>
                    <option value="non_reporting">Non-Reporting</option>
                    <option value="closed">Closed</option>
                  </React.Fragment>
                )}
                {this.props.query?.workflow != 'global' &&
                  Object.entries(this.props.available_line_lists[this.props.query?.workflow]).map(([ll, llProps]) => {
                    return (
                      <option key={ll} value={ll}>
                        {llProps.label}
                      </option>
                    );
                  })}
              </Form.Control>
            </InputGroup>
          </Col>
          <Col md={24} className="my-1 px-1">
            <JurisdictionFilter
              jurisdiction_paths={this.props.jurisdiction_paths}
              jurisdiction={this.props.query?.jurisdiction}
              scope={this.props.query?.scope}
              onJurisdictionChange={jurisdiction => {
                if (jurisdiction !== this.props.query?.jurisdiction) {
                  this.props.onQueryChange('jurisdiction', jurisdiction, () => {
                    this.updateAssignedUsers();
                  });
                }
              }}
              onScopeChange={scope => this.props.onQueryChange('scope', scope)}
            />
          </Col>
          <Col md={24} className="my-1 px-1">
            <AssignedUserFilter
              workflow={this.props.query?.workflow}
              assigned_users={this.state.assigned_users}
              assigned_user={this.props.query?.user}
              onAssignedUserChange={user => this.props.onQueryChange('user', user)}
            />
          </Col>
          <Col md={24} className="my-1 px-1">
            <InputGroup size="sm" className="d-flex justify-content-between">
              <InputGroup.Prepend>
                <OverlayTrigger overlay={<Tooltip>Search by monitoree name, date of birth, state/local id, cdc id, or nndss/case id</Tooltip>}>
                  <InputGroup.Text className="rounded-0">
                    <FontAwesomeIcon icon="search" />
                    <label htmlFor="search" className="ml-1 mb-0">
                      Dashboard Search Terms
                    </label>
                  </InputGroup.Text>
                </OverlayTrigger>
              </InputGroup.Prepend>
              <Form.Control
                autoComplete="off"
                size="sm"
                id="search"
                value={this.props.query?.search || ''}
                onChange={event => this.props.onQueryChange('search', event?.target?.value)}
                onKeyPress={event => {
                  if (event.which === 13) {
                    event.preventDefault();
                  }
                }}
              />
              <AdvancedFilter
                advancedFilterUpdate={filter =>
                  this.props.onQueryChange(
                    'filter',
                    filter?.filter(field => field?.filterOption != null)
                  )
                }
                authenticity_token={this.props.authenticity_token}
                updateStickySettings={false}
              />
            </InputGroup>
          </Col>
        </Row>
      </Form.Group>
    );
  }
}

PatientsFilters.propTypes = {
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.object,
  jurisdiction: PropTypes.object,
  available_workflows: PropTypes.array,
  available_line_lists: PropTypes.object,
  query: PropTypes.object,
  onQueryChange: PropTypes.func,
};

export default PatientsFilters;
