import React from 'react';
import { PropTypes } from 'prop-types';
import { Button, ButtonGroup, Dropdown, DropdownButton, Form, Modal, ProgressBar } from 'react-bootstrap';
import axios from 'axios';

import Export from './Export';
import Import from './Import';
import confirmDialog from '../util/ConfirmDialog';

const importOptions = [
  { importType: 'epix', workflowSpecific: true, label: 'Epi-X' },
  { importType: 'saf', workflowSpecific: true, label: 'Sara Alert Format' },
];

class PublicHealthHeader extends React.Component {
  constructor(props) {
    super(props);
    let allowedImportOptions = importOptions;
    if (props?.header_action_buttons?.import_options?.import) {
      let import_labels = Object.values(props.header_action_buttons?.import_options?.import.options).map(x => x.label);
      allowedImportOptions = allowedImportOptions.filter(x => import_labels.includes(x.label));
    }
    this.state = {
      counts: {},
      showUploadModal: false,
      showImportModal: false,
      uploading: false,
      importOptions: allowedImportOptions,
    };
  }

  componentDidMount() {
    axios.get(window.BASE_PATH + '/public_health/patients/counts/workflow').then(response => {
      if (response && response.data) {
        this.setState({ counts: response.data });
      }
    });
  }

  selectFileForUpload(event, type) {
    this.setState({ file: event.target.files[0], fileType: type });
  }

  uploadFile = () => {
    if (this.state.file && this.state.fileType) {
      this.setState({ uploading: true }, () => {
        axios.defaults.headers.common['X-CSRF-Token'] = this.props.authenticity_token;
        const config = { headers: { 'content-type': 'multipart/form-data' } };
        const formData = new FormData();
        formData.append('file', this.state.file);
        const url = `${window.BASE_PATH}/import/${this.props.workflow}/${this.state.fileType === 'epix' ? 'epix' : 'sara_alert_format'}`;
        axios.post(url, formData, config).then(response => {
          this.setState({
            uploading: false,
            importData: response.data,
            showUploadModal: false,
            showImportModal: true,
          });
        });
      });
    }
  };

  renderImportModal() {
    return (
      <Modal
        dialogClassName="modal-import"
        backdrop={this.state.importData?.errors?.length > 0 ? true : 'static'}
        scrollable="true"
        show={this.state.showImportModal}
        onHide={async () => {
          if (this.state.importData.errors.length > 0) {
            this.setState({ showImportModal: false, importType: null, importData: null });
          } else if (this.importComponent.state.progress > 0) {
            this.importComponent.stopImport('X');
          } else if (this.importComponent.state.accepted.length > 0) {
            const confirmText = 'You are about to stop the import process. Are you sure you want to do this?';
            const options = {
              title: 'Stop Import',
              okLabel: 'Proceed to Stop',
              cancelLabel: 'Return to Import',
              additionalNote: 'Records imported prior to clicking "X" will not be deleted from the system.',
            };
            if (await confirmDialog(confirmText, options)) {
              location.href = `${window.BASE_PATH}/public_health/${this.props.workflow === 'exposure' ? '' : 'isolation'}`;
            }
          } else {
            const confirmText = 'You are about to cancel the import process. Are you sure you want to do this?';
            const options = {
              title: 'Cancel Import',
              okLabel: 'Proceed to Cancel',
              cancelLabel: 'Return to Import',
            };
            if (await confirmDialog(confirmText, options)) {
              this.setState({ showImportModal: false, importType: null, importData: null });
            }
          }
        }}>
        <Modal.Header closeButton>
          {this.state.importData && (
            <React.Fragment>
              {this.state.importData.errors.length > 0 && (
                <Modal.Title className="h5">{this.state.importType === 'epix' ? 'Import Epi-X' : 'Import Sara Alert Format'} (error)</Modal.Title>
              )}
              {this.state.importData.errors.length === 0 && (
                <Modal.Title className="h5">
                  {this.state.importType === 'epix' ? 'Import Epi-X' : 'Import Sara Alert Format'} ({this.props.workflow})
                </Modal.Title>
              )}
            </React.Fragment>
          )}
        </Modal.Header>
        <Modal.Body>
          {this.state.importData && this.state.importData.patients && this.state.importData.errors && (
            <Import
              workflow={this.props.workflow}
              patients={this.state.importData.patients}
              errors={this.state.importData.errors}
              authenticity_token={this.props.authenticity_token}
              ref={instance => {
                this.importComponent = instance;
              }}
            />
          )}
        </Modal.Body>
      </Modal>
    );
  }

  renderUploadModal() {
    return (
      <Modal size="md" show={this.state.showUploadModal} onHide={() => this.setState({ showUploadModal: false, importType: null })}>
        <Modal.Header closeButton>
          {this.state.importType === 'epix' && <Modal.Title className="h5">{`Import Epi-X (${this.props.workflow})`}</Modal.Title>}
          {this.state.importType === 'saf' && <Modal.Title className="h5">{`Import Sara Alert Format (${this.props.workflow})`}</Modal.Title>}
        </Modal.Header>
        <Modal.Body>
          {this.state.importType === 'saf' && (
            <div className="mb-3">
              <a href={`${window.location.origin}/Sara%20Alert%20Import%20Format.xlsx`}>Download formatting guidance</a> (Updated 5/18/2021)
            </div>
          )}
          <Form inline>
            <Form.File>
              <Form.File.Input onChange={event => this.selectFileForUpload(event, this.state.importType)}></Form.File.Input>
            </Form.File>
            <Button className="float-right ml-auto" disabled={!this.state.file} onClick={this.uploadFile}>
              <i className="fas fa-upload"></i> Upload
            </Button>
          </Form>
          {this.state.uploading && <ProgressBar animated striped now={100} className="mt-3" />}
        </Modal.Body>
      </Modal>
    );
  }

  render() {
    return (
      <React.Fragment>
        <ButtonGroup>
          {this.props.abilities.enrollment && this.props.header_action_buttons.enroll && (
            <Button
              variant="primary"
              className="ml-2 mb-4"
              href={`${window.BASE_PATH}/patients/new${this.props.workflow === 'exposure' ? '' : '?isolation=true'}`}>
              <span>
                <i className="fas fa-user-plus"></i> {this.props.header_action_buttons.enroll.label}
              </span>
            </Button>
          )}
          {this.props.abilities.export && this.props.header_action_buttons.export && (
            <Export
              authenticity_token={this.props.authenticity_token}
              jurisdiction_paths={this.props.jurisdiction_paths}
              jurisdiction={this.props.jurisdiction}
              tabs={this.props.tabs}
              workflow={this.props.workflow}
              export_options={this.props.header_action_buttons}
              query={this.props.query}
              all_monitorees_count={this.state.counts.exposure + this.state.counts.isolation}
              current_monitorees_count={this.props.current_monitorees_count}
              custom_export_options={this.props.custom_export_options}
            />
          )}
          {this.props.abilities.import && this.props.header_action_buttons.import && (
            <DropdownButton
              as={ButtonGroup}
              size="md"
              className="ml-2 mb-4"
              title={
                <React.Fragment>
                  <i className="fas fa-upload"></i> {this.props.header_action_buttons.import.label || 'Import'}{' '}
                </React.Fragment>
              }>
              {importOptions.map((io, ioIndex) => (
                <Dropdown.Item key={`import-option-${ioIndex}`} onClick={() => this.setState({ importType: io.importType, showUploadModal: true })}>
                  {io.label} {io.workflowSpecific && `(${this.props.query.workflow})`}
                </Dropdown.Item>
              ))}
            </DropdownButton>
          )}
        </ButtonGroup>

        <ButtonGroup className="float-right mb-4 mr-2">
          {this.props.available_workflows.map(value => {
            return (
              <Button
                key={value.name}
                variant={this.props.workflow === value.name ? 'primary' : 'outline-primary'}
                href={`${window.BASE_PATH}/dashboard/${this.props.playbook}/${value.name}`}>
                <i className="fas fa-people-arrows"></i> {value.label} Monitoring{' '}
              </Button>
            );
          })}
        </ButtonGroup>

        {this.renderUploadModal()}
        {this.renderImportModal()}
      </React.Fragment>
    );
  }
}

PublicHealthHeader.propTypes = {
  authenticity_token: PropTypes.string,
  jurisdiction_paths: PropTypes.object,
  //workflow: PropTypes.oneOf(['exposure', 'isolation']),
  workflow: PropTypes.string,
  jurisdiction: PropTypes.object,
  tabs: PropTypes.object,
  abilities: PropTypes.exact({
    analytics: PropTypes.bool,
    enrollment: PropTypes.bool,
    export: PropTypes.bool,
    import: PropTypes.bool,
  }),
  query: PropTypes.object,
  current_monitorees_count: PropTypes.number,
  custom_export_options: PropTypes.object,
  available_workflows: PropTypes.array,
  playbook: PropTypes.string,
  header_action_buttons: PropTypes.object,
};

export default PublicHealthHeader;
