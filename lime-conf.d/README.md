
# Post-Deployment LimeSurvey Setup

## Review LimeSurvey Deployment Status
1. Verify the containers have started.

    The services that make up the LimeSurvey server are found in two containers: limesurvey and survey_db.  When using docker-compose, the name of the deployment folder will be prepended and an instance number will be appended (e.g., my_deploy-limesurvey_1). Verify that these containers are running and that the limesurvey container has port 80/tcp open and the survey-db container has port 3306/tcp open.

<details>
<summary>Click here to review instruction for docker-compose.</summary>

    a. Ensure the deployment folder is the current working directory.
    b. Run the following on the command line to view the list of active containers

    docker container ls

    c. The container status should be Up with the container-scope ports mentioned above listed in the Ports column.

</details>

2. Verify several run-time folders have been created.
The following folders should have been created within the `lime-runtime` folder in the deployment directory.


* *lime-runtime*
   * *config*
   * *config-copy*
   * *plugins*
   * *upload*

    These folders are created as local docker volume mounts for persisting files used by LimeSurvey. The config-copy directory will be empty; each of the others should have content.

    When running in a local docker environment, you will see that the LimeSurvey container set the owner of config, plugins, and upload to weww-data. If this needs to be changed, ensure that www-data has read and write privileges to these folders and the files within them. The LimeSurvey manual provides additional information. (https://manual.limesurvey.org/Installation_security_hints)


## Confirm LimeSurvey Graphical User Interface is Running
The LimeSurvey home page is found at https://myservername.domain/index.php

After initial installation, this page should present the LimeSurvey logo and a sentence that introduces a list of available surveys -- of which there are none.

The LimeSurvey adminsration login page is at https://myservername.domain/index.php/admin. Open this page in your browser and log in using the credentials that were provieded in the configuration file, `survey-compose.env`.

After logging in, you will receive a warning that SSL is not enforced. This is expected; click Close to close the dialog.  The use of https (i.e., TLS/SSL) is being enforced between LimeSurvey users (e.g., survey takers and survey managers) and NGINIX.  When NGINX receives a web request, it relays it via an isolated backend virtual network to the limesurvey container using http.  Responses from LimeSurvey go back through NGINX, which sends the response back to the original requester on the https connection.

Run through the following:

- Check the software version

    The software version is presented in the lower right of the page. This value should match the tag in the docker image (e.g., acspri/limesurve:5.1.8). Click the hyperlink and check that the values in the system information dialog are as expected.
* Check the data integrity.

    From the menu bar at the top of the page, select Configuration | Data Integrity. If any errors or warnings are presented, the installation was not successful.

* Update the administrator profile.

    Select the drop down menu in the upper right associated with the current user and select `My Account`.  the most important actions at this time are to update the Full Name, change the password, and ensure the email address is correct.

* Log out 

   Select the drop down menu in the upper right associated with the current user and select `Logout`.

## Update Environment Variable Configuration File

Each time the limesurvey docker container starts, it will try to set the administrator username and password.  This can result in the password being reset to its initial value. Therefore, it's important to comment our or delete these lines.

Edit the configuration file, survey-compose.env, in the deployment directory. Comment out or delete the lines for the following two environment variables: 
* LIMESURVEY_ADMIN_USER
* LIMESURVEY_ADMIN_PASSWORD

Save the file and exit the editor.

## Secure LimeSurvey config.php file
LimeSurvey stores configuration information, including username and password for the database user, in a file, `/applicaion/config/config.php`.  This file is located under the web server's root directory. Though it is unlikely that this file could be directly accessed from a user's browser, the LimeSurvey manual [here](https://manual.limesurvey.org/Installation_security_hints/en#The_access_to_the_config.php_file) recommends replacing the content of config.php with a statement that includes the configuration information from a file located in a non-web directory.

The steps are given below. Note that you may need sudo privileges to manipulate files in the directories under `lime-runtime`.
1. Set the working directory to the deployment directory.
2. Stop the limesurvey container.

    `docker-compose stop limesurvey`
3. Move the file, `lime-runtime/config/config.php` to the `lime-runtime/config-copy/` directory.

    `sudo mv lime-runtime/config/config.php lime-runtime/config-copy/`

4. Copy the example replacement config.php file from the source repository to `lime-runtime/config`.

    `sudo cp <src_repo>/lime-conf.d/config.php.replacement <deploy_dir>/lime-runtime/config/config.php`

    The "safe" config.php should just have an include statement and look like the following: (Note that PHP files often do NOT contain a closing '?>')

    ```php
    <?php if (!defined('BASEPATH')) {
        exit('No direct script access allowed');
    }
    return include("/etc/lime-conf.d/config.php");
    ```

5. Verify that the www-data user (used by LimeSurvey) has read privileges to the config-copy folder

    `sudo chown -R www-data lime-runtime/config-copy`
    
6. Start the limesurvey container

    `docker-compose start limesurvey`

7. Log into the LimeSurvey administration page to confirm the application is working.

# Configure LimeSurvey Global Settings
Log in to the LimeSurvey Administrator interace (https://myservername.domain/index.php/admin). Select Configuration | Global to display the Global Settings page.

LimeSurvey Manual: [Global Settings](https://manual.limesurvey.org/Global_settings)

## General

1. Set the site name.
2. Select a different default theme for surveys, if desired.
3. Select a different Administration them, if desired.
4. LimeSurvey uses UTC time by default.  Enter the difference from UTC for your local time zone, if desired.
5. Click Save

## Email setting
1.  Set the default site admin email address and name.  This is used for system messages.
2. Select the Email method appropriate for your environment and enter values for the required fields.
3. Click Save
4. CLick the button at the bottom of the page to send a test email. Note you must save changes to the page before trying to send the test email.

## Email Bounce tracking
Lime Survey Manual: [Email Bounce Tracking](https://manual.limesurvey.org/Email_bounce_tracking_system)

**TBD**

## Security
The defaults should be appropriate. If desired, test the provided link to see if enabling Force HTTPS might work for your environment. Note the warning notice on the settings page before saving this setting.

## User Administration
Update the welcome message to suit the needs of your site.

## Lanugage
Select the languages that should be visible to LimeSurvey users (administrators and survey takers). The Add button moves items selected in the Hidden panel to Visible.  The Remove button moves items selected in the Visible panel to Hidden.

Click Save when done.

## Interfaces
1. Enable the JSON-RPC interface
2. Click Save

## Configuration Verification
After changing the Global Settings, log out out of the Administration.  
On the log in page, check that the available languages has changed. Log back in and inspect that other settings are as expected.

Consider resstarting the limesurvey container as a way to verify the setting changes were persisted.


# LimeSurvey Site Look and Feel Customization
**TBD**

# General Administration Actions

## Create a Survey Manager role/account
**TBD**

Create user role with sufficient permissions to create and manage surveys without the distraction of full administrator privileges.



# System and Database Administation

## Backup database - TBD
**INCOMPLETE and UNVERIFIED**

1. Enter Maintenance Mode? (Global Settings | General)
1. Clear assets cache? (Global Settings general)
1. Stop limesurvey container
1. Update limesurvey image version in docker-compose file
1. Rebuild and start the limesurvey container
    `docker-compose up --build limesurvey`
1. Open web browser
1. Clear browser cache and cookies if it was previously used to access LimeSurvey
1. Log in as admin
1. Check the software version number presented in the lower right in the page footer is as expected.
1. Go to Configuration | Data Integrity. See if a database schema update is required.
1. Verify the list of available surveys is correct.
1. Leave Maintenance mode?

## Upgrading to a New LimeSurvey Version - TBD
**INCOMPLETE and UNVERIFIED**

LimeSurvey Manual: [Upgrading from a Previous Version](https://manual.limesurvey.org/Upgrading_from_a_previous_version)

Note that the steps in the manual need to be adapted to an installation running in docker containers. 

Note: The Docker image tag (e.g., acspri/limesurvey:5.1.18) corresponds to the  LimeSurvey software version.

The basic steps are:
1. Backup the data
2. Stop the limesurvey container.
3. Update the Docker image tag in docker-compose.yml
4. Start the limesurvey container
5. Log in to the administrator interface.

    a. Look for messages about a need to update the database schema.



# Resources
* [LimeSurvey Manual](https://manual.limesurvey.org/)
* [acspri/limesurvey](https://hub.docker.com/r/acspri/limesurvey) Docker Image at [dockerhub](https://hub.docker.com/)
* [LimeSurvey surce code repository](https://github.com/LimeSurvey/LimeSurvey) at GitHub
* [LimeSurvey Community Edition](https://community.limesurvey.org/) web site

### Articles of Potential Relevance
* [Installing LimeSurvey with Docker on Ubuntu 16.04 with Nginx and Mariadb](https://tech.oeru.org/installing-limesurvey-docker-ubuntu-1604-nginx-and-mariadb)
