import React from 'react';
import { PropTypes } from 'prop-types';
import { Badge, ButtonGroup, Card, Dropdown, DropdownButton, Form, InputGroup, Modal, Nav, OverlayTrigger, TabContent, Tooltip } from 'react-bootstrap';
import { ToastContainer } from 'react-toastify';
import ReactTooltip from 'react-tooltip';
import axios from 'axios';
//import _ from 'lodash';

import CloseRecords from './bulk_actions/CloseRecords';
import CustomTable from '../layout/CustomTable';
import EligibilityTooltip from '../util/EligibilityTooltip';
import { patientHref } from '../../utils/Navigation';
import { formatDateOfBirthTableCell } from '../../utils/PatientFormatters';

class PatientsTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      table: {
        colData: [
          { field: 'name', label: 'Monitoree', isSortable: true, tooltip: null, filter: this.linkPatient },
          { field: 'jurisdiction', label: 'Jurisdiction', isSortable: true, tooltip: null },
          { field: 'dob', label: 'Date of Birth', isSortable: true, tooltip: null, filter: this.formatDOB },
        ],
        displayedColData: [],
        rowData: [],
        totalRows: 0,
      },
      loading: false,
      actionsEnabled: false,
      selectedPatients: [],
      selectAll: false,
      jurisdiction_paths: {},
      assigned_users: [],
      query: {
        //workflow: props.workflow,
        tab: props.default_tab ?? Object.keys(props.tabs)[0],
        jurisdiction: props.jurisdiction.id,
        scope: 'all',
        user: null,
        search: '',
        page: 0,
        entries: 25,
        tz_offset: new Date().getTimezoneOffset(),
      },
      entryOptions: [10, 15, 25, 50, 100],
      cancelToken: axios.CancelToken.source(),
    };
  }

  componentDidMount() {
    const query = {};
    let search = this.getLocalStorage(`GlyphSearch`);
    let page = this.getLocalStorage(`GlyphPage`);
    let sortField = this.getLocalStorage(`GlyphSortField`);
    let sortDirection = this.getLocalStorage(`GlyphSortDirection`);
    // let priorWorkflow = this.getLocalStorage(`Workflow`);
    // if (priorWorkflow && this.props.workflow === priorWorkflow) {
    if (parseInt(page)) {
      query.page = parseInt(page);
      //}
    }

    if (sortField && sortDirection) {
      query.order = sortField;
      query.direction = sortDirection === 'asc' ? 'asc' : 'desc';
    } else {
      this.removeLocalStorage(`GlyphPage`);
      this.removeLocalStorage(`GlyphSortField`);
      this.removeLocalStorage(`GlyphSortDirection`);
      //this.setLocalStorage(`Workflow`, this.props.workflow);
      query.page = 0;
    }

    if (search) {
      query.search = search;
    }
    this.updateTable({ ...this.state.query, ...query });

    // TODO - Remove Hardcoded Values
    const count = {};
    count[`enrolledCount`] = 2;
    count[`closedCount`] = 1;
    count[`allCount`] = 3;
    this.setState(count);

    // // fetch patient and tab counts
    // Object.keys(this.props.tabs).forEach(tab => {
    //   const count = {};
    //   count[`${tab}Count`] = 2;
    //   this.setState(count);
    // });

    // {
    // axios.get(`${window.BASE_PATH}/public_health/patients/counts/${tab}`).then(response => {
    //   const count = {};
    //   count[`${tab}Count`] = response.data.total;
    //   this.setState(count);
    // });
  }

  handleTabSelect = tab => {
    this.removeLocalStorage(`GlyphPage`);
    const query = {};
    query.tab = tab;

    this.setState(
      state => {
        return { query: { ...state.query, ...query, page: 0 } };
      },
      () => {
        this.updateTable(this.state.query);
        this.setLocalStorage(`${this.props.jurisdiction.id}Tab`, tab);
        //this.setLocalStorage(`${this.props.workflow}Tab`, tab);
      }
    );
  };

  /**
   * Called when a page is clicked in the pagination component.
   * Updates the table based on the selected page.
   *
   * @param {Object} page - Page object from react-paginate
   */
  handlePageUpdate = page => {
    this.setState(
      state => {
        return {
          query: { ...state.query, page: page.selected },
        };
      },
      () => {
        this.updateTable(this.state.query);
      }
    );
  };

  /**
   * Called when the number of entries to be shown on a page changes.
   * Updates state and then calls table update handler.
   * @param {SyntheticEvent} event - Event when num entries changes
   */
  handleEntriesChange = event => {
    const value = event?.target?.value || event;
    this.setState(
      state => {
        return {
          query: { ...state.query, entries: parseInt(value), page: 0 },
        };
      },
      () => {
        this.updateTable(this.state.query);
      }
    );
  };

  handleJurisdictionChange = jurisdiction => {
    if (jurisdiction !== this.state.query.jurisdiction) {
      this.updateTable({ ...this.state.query, jurisdiction, page: 0 });
    }
  };

  handleScopeChange = scope => {
    if (scope !== this.state.query.scope) {
      this.updateTable({ ...this.state.query, scope, page: 0 });
    }
  };

  handleSearchChange = event => {
    this.updateTable({ ...this.state.query, search: event.target?.value, page: 0 });
    this.removeLocalStorage(`GlyphPage`);
    this.setLocalStorage(`GlyphSearch`, event.target.value);
  };

  handleKeyPress = event => {
    if (event.which === 13) {
      event.preventDefault();
    }
  };

  /**
   * Callback called when child Table component detects a selection change.
   * @param {Number[]} selectedRows - Array of selected row indices.
   */
  handleSelect = selectedRows => {
    // All rows are selected if the number selected is the max number shown or the total number of rows completely
    const selectAll = selectedRows.length >= this.state.query.entries || selectedRows.length >= this.state.table.totalRows;
    this.setState({
      actionsEnabled: selectedRows.length > 0,
      selectedPatients: selectedRows,
      selectAll,
    });
  };

  updateTable = query => {
    // cancel any previous unfinished requests to prevent race condition inconsistencies
    this.state.cancelToken.cancel();

    // generate new cancel token for this request
    const cancelToken = axios.CancelToken.source();

    this.setState(
      state => {
        return { query: { ...state.query, ...query }, cancelToken, loading: true };
      },
      () => {
        this.setState(state => {
          const displayedColData = this.state.table.colData;
          return {
            table: { ...state.table, displayedColData, rowData: this.queryServer, totalRows: this.queryServer.count },
            selectedPatients: [],
            selectAll: false,
            loading: false,
            actionsEnabled: false,
          };
        });
        // this.queryServer; // this.queryServer(this.state.query);
      }
    );

    // set query
    this.props.setQuery(query);
  };

  // TODO - Remove Hardcoded Values
  queryServer = [
    {
      id: '1',
      name: 'Alice Alice',
      jurisdiction: 'Trial 1',
      dob: '2020-01-01',
      active: true,
    },
    {
      id: '2',
      name: 'Bob Bob',
      jurisdiction: 'Trial 2',
      dob: '2020-02-02',
      active: true,
    },
    {
      id: '3',
      name: 'Cat Cat',
      jurisdiction: 'Trial 3',
      dob: '2000-03-03',
      active: false,
    },
  ];

  // queryServer = _.debounce(query => {
  //   axios
  //     .post(window.BASE_PATH + '/public_health/patients', { query, cancelToken: this.state.cancelToken.token })
  //     .catch(error => {
  //       if (!axios.isCancel(error)) {
  //         this.setState(state => {
  //           return {
  //             table: { ...state.table, rowData: [], totalRows: 0 },
  //             loading: false,
  //           };
  //         });
  //       }
  //     })
  //     .then(response => {
  //       if (response && response.data && response.data.linelist) {
  //         this.setState(state => {
  //           const displayedColData = this.state.table.colData.filter(colData => response.data.fields.includes(colData.field));
  //           return {
  //             table: { ...state.table, displayedColData, rowData: response.data.linelist, totalRows: response.data.total },
  //             selectedPatients: [],
  //             selectAll: false,
  //             loading: false,
  //             actionsEnabled: false,
  //           };
  //         });

  //         // update count for custom export
  //         this.props.setFilteredMonitoreesCount(response.data.total);
  //       } else {
  //         this.setState({
  //           selectedPatients: [],
  //           selectAll: false,
  //           actionsEnabled: false,
  //           loading: false,
  //         });

  //         // update count for custom export
  //         this.props.setFilteredMonitoreesCount(0);
  //       }
  //     });
  // }, 500);

  linkPatient = data => {
    const name = data.value;
    const rowData = data.rowData;

    return this.createPatientLink(rowData.id, name);
  };

  linkReporter = data => {
    return this.createPatientLink(data.value, data.value);
  };

  createPatientLink = (id, text) => {
    //return <a href={patientHref(id, this.props.workflow)}>{text}</a>;
    return <a href={patientHref(id, this.props.jurisdiction.id)}>{text}</a>;
  };

  formatDOB = data => {
    return formatDateOfBirthTableCell(data.rowData.dob, data.rowData.id);
  };

  getRowCheckboxAriaLabel = rowData => {
    return `Monitoree ${rowData.name}`;
  };

  // Adds the className `selected-row` to those rows who have been selected with the Bulk Action checkbox
  getRowClassName = rowData => {
    const isSelected = this.state.selectedPatients.filter(x => this.state.table.rowData[Number(x)].id === rowData.id).length;
    return isSelected ? 'selected-row' : null;
  };

  createEligibilityTooltip = data => {
    const reportEligibility = data.value;
    const rowData = data.rowData;
    return <EligibilityTooltip id={rowData.id.toString()} report_eligibility={reportEligibility} inline={false} />;
  };

  renderFollowUpTooltip = data => {
    const flaggedForFollowUp = data.value;
    const rowData = data.rowData;
    return (
      <React.Fragment>
        {flaggedForFollowUp.follow_up_reason && (
          <React.Fragment>
            <span key={`flagged-icon-${rowData.id}`} data-for={`flagged-${rowData.id}`} data-tip="">
              <div className="text-center ml-0">
                <i className="fa-fw fas fa-flag"></i>
              </div>
            </span>
            <ReactTooltip key={`flagged-tooltip-${rowData.id}`} id={`flagged-${rowData.id}`} multiline={true} place="right" type="dark" effect="solid">
              <div>
                Monitoree is flagged for follow-up.
                <br />
                {flaggedForFollowUp.follow_up_reason}
                {flaggedForFollowUp.follow_up_note && flaggedForFollowUp.follow_up_note.length < 75 && <span>{': ' + flaggedForFollowUp.follow_up_note}</span>}
                {flaggedForFollowUp.follow_up_note && flaggedForFollowUp.follow_up_note.length >= 75 && (
                  <span>{': ' + flaggedForFollowUp.follow_up_note.slice(0, 75) + ' ...'}</span>
                )}
              </div>
            </ReactTooltip>
          </React.Fragment>
        )}
      </React.Fragment>
    );
  };

  /**
   * Get a local storage value
   * @param {String} key - relevant local storage key
   */
  getLocalStorage = key => {
    // It's rare this is needed, but we want to make sure we won't fail on Firefox's NS_ERROR_FILE_CORRUPTED
    try {
      return localStorage.getItem(key);
    } catch (error) {
      console.error(error);
      return null;
    }
  };

  /**
   * Set a local storage value
   * @param {String} key - relevant local storage key
   * @param {String} value - value to set
   */
  setLocalStorage = (key, value) => {
    // It's rare this is needed, but we want to make sure we won't fail on Firefox's NS_ERROR_FILE_CORRUPTED
    try {
      localStorage.setItem(key, value);
    } catch (error) {
      console.error(error);
    }
  };

  /**
   * Remove a local storage value
   * @param {String} key - relevant local storage key
   */
  removeLocalStorage = key => {
    // It's rare this is needed, but we want to make sure we won't fail on Firefox's NS_ERROR_FILE_CORRUPTED
    try {
      localStorage.removeItem(key);
    } catch (error) {
      console.error(error);
    }
  };

  render() {
    return (
      // <div className={`dashboard ${this.props.workflow}-dashboard mx-2 pb-4`}>
      <div className={`dashboard ${this.props.jurisdiction.id}-dashboard mx-2 pb-4`}>
        <Nav variant="tabs" activeKey={this.state.query.tab}>
          {Object.entries(this.props.tabs).map(([tab, tabProps]) => {
            return (
              <Nav.Item key={tab}>
                <Nav.Link eventKey={tab} onSelect={this.handleTabSelect} id={`${tab}_tab`}>
                  <span className="large-tab">{tabProps.label}</span>
                  <span className="small-tab" aria-label={tabProps.label}>
                    {tabProps.abbreviatedLabel || tabProps.label}
                  </span>
                  <Badge variant={tabProps.variant} className="badge-larger-font ml-1">
                    <span>{`${tab}Count` in this.state ? this.state[`${tab}Count`] : ''}</span>
                  </Badge>
                </Nav.Link>
              </Nav.Item>
            );
          })}
        </Nav>
        <TabContent>
          <Card style={{ marginTop: '-1px' }}>
            <Card.Body className="px-4">
              <Form className="my-1">
                <InputGroup size="sm" className="d-flex justify-content-between">
                  <InputGroup.Prepend>
                    <OverlayTrigger overlay={<Tooltip>Search by monitoree name or date of birth</Tooltip>}>
                      <InputGroup.Text className="rounded-0">
                        <i className="fas fa-search"></i>
                        <label htmlFor="search" className="ml-1 mb-0">
                          Search
                        </label>
                      </InputGroup.Text>
                    </OverlayTrigger>
                  </InputGroup.Prepend>
                  <Form.Control
                    autoComplete="off"
                    size="sm"
                    id="search"
                    aria-label="Search"
                    value={this.state.query.search || ''}
                    onChange={this.handleSearchChange}
                    onKeyPress={this.handleKeyPress}
                  />
                  <DropdownButton
                    as={ButtonGroup}
                    size="sm"
                    variant="primary"
                    title={
                      <React.Fragment>
                        <i className="fas fa-tools"></i> Bulk Actions{' '}
                      </React.Fragment>
                    }
                    className="ml-2"
                    disabled={!this.state.actionsEnabled}>
                    {this.state.query.tab !== 'closed' && (
                      <Dropdown.Item className="px-3" onClick={() => this.setState({ action: 'Close Records' })}>
                        <i className="fas fa-window-close text-center" style={{ width: '1em' }}></i>
                        <span className="ml-2">Close Records</span>
                      </Dropdown.Item>
                    )}
                  </DropdownButton>
                </InputGroup>
              </Form>
              <div className="patients-table">
                <CustomTable
                  dataType="patients"
                  columnData={this.state.table.displayedColData}
                  rowData={this.state.table.rowData}
                  totalRows={this.state.table.totalRows}
                  handleTableUpdate={query => this.updateTable({ ...this.state.query, order: query.orderBy, page: query.page, direction: query.sortDirection })}
                  handleSelect={this.handleSelect}
                  handleEntriesChange={this.handleEntriesChange}
                  handlePageUpdate={this.handlePageUpdate}
                  getRowClassName={this.getRowClassName}
                  getRowCheckboxAriaLabel={this.getRowCheckboxAriaLabel}
                  isSelectable={true}
                  isEditable={false}
                  isLoading={this.state.loading}
                  page={this.state.query.page}
                  selectedRows={this.state.selectedPatients}
                  selectAll={this.state.selectAll}
                  entryOptions={this.state.entryOptions}
                  entries={parseInt(this.state.query.entries)}
                  orderBy={this.state.query.order !== undefined ? this.state.query.order : ''}
                  sortDirection={this.state.query.direction !== undefined ? this.state.query.direction : ''}
                />
              </div>
            </Card.Body>
          </Card>
        </TabContent>
        <Modal size="lg" centered show={this.state.action !== undefined} onHide={() => this.setState({ action: undefined })}>
          <Modal.Header closeButton>
            <Modal.Title>{this.state.action}</Modal.Title>
          </Modal.Header>
          {this.state.action === 'Close Records' && (
            <CloseRecords
              authenticity_token={this.props.authenticity_token}
              patients={this.state.table.rowData.filter((_, index) => this.state.selectedPatients.includes(index))}
              monitoring_reasons={this.props.monitoring_reasons}
              close={() => this.setState({ action: undefined })}
            />
          )}
        </Modal>
        <ToastContainer position="top-center" autoClose={2000} closeOnClick pauseOnVisibilityChange draggable pauseOnHover />
      </div>
    );
  }
}

PatientsTable.propTypes = {
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.object,
  all_assigned_users: PropTypes.array,
  //workflow: PropTypes.oneOf(['global', 'exposure', 'isolation']),
  jurisdiction: PropTypes.exact({
    id: PropTypes.number,
    path: PropTypes.string,
  }),
  tabs: PropTypes.object,
  default_tab: PropTypes.string,
  setQuery: PropTypes.func,
  setFilteredMonitoreesCount: PropTypes.func,
  monitoring_reasons: PropTypes.array,
};

export default PatientsTable;
