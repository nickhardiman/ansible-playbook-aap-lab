#-------------------------
# Set up the hypervisor 
# Instructions 

# !!! make a new role machine-hypervisor-configure.yml
# and migrate much of this crap to that and to collection roles. 

# Log into your RHEL 9 install host.
# Download this script to your home directory.
#   curl -O https://raw.githubusercontent.com/nickhardiman/ansible-playbook-aap2-refarch/main/bootstrap-refarch.sh 
# Read it. 
# Edit and change my details to yours.
#   More details on these attributes below. 
#   1. Set RHSM (Red Hat Subscription Manager) account.
#   2. Set ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN.
#   3. Set OFFLINE_TOKEN.
#   4. Change git name, email and user.
#
# This script now contains sensitive information. 
# Protect it. 
# Don't upload it to Github.
#
# Run this script
#   bash -x bootstrap.sh

#-------------------------
# Edit and change my details to yours.


# 1. Set RHSM (Red Hat Subscription Manager) account.
# If you don't have one, get a free
# Red Hat Enterprise Linux Individual Developer Subscription.
# Sign up for your free RHSM (Red Hat Subscription Manager) account at 
#  https://developers.redhat.com/.
# Check your account works by logging in at https://access.redhat.com/.
# You can register up to 16 physical or virtual nodes.
# This inventory lists 8.
# (https://github.com/nickhardiman/ansible-playbook-build/blob/main/inventory.ini)
RHSM_USER=my_developer_user
RHSM_PASSWORD='my developer password'


# 2. Set ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN.
# Anyone with an RHSM account can use Red Hat Automation Hub.
# You can download Ansible collections after authenticating with a token.
#
# Open the API token page. 
#   https://console.redhat.com/ansible/automation-hub/token#
# Click the button to generate a token.
# Copy the token.
# Paste the token here. 
# The ansible-galaxy command looks for this environment variable.
export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_TOKEN=eyJhbGciOi...(about 800 more characters)...asdf
# (You can also put your offline token in ansible.cfg.)


# 3. Set OFFLINE_TOKEN.
# Authenticate to Red Hat portal using an API token.
# After the hypervisor is installed, 
# the role https://github.com/nickhardiman/ansible-collection-platform/tree/main/roles/iso_rhel_download
# downloads RHEL install DVD ISO files. 
# The role uses one of the Red Hat APIs, which requires an API token.
#
# Open the API token page. 
#   https://access.redhat.com/management/api
# Click the button to generate a token.
# Copy the token.
# Paste the token here. 
# The playbook will copy the value from this environment variable.
export OFFLINE_TOKEN=eyJh...(about 600 more characters)...xmtyM


# 4. Change git name, email and user.
GIT_NAME="Nick Hardiman"
GIT_EMAIL=nick@email-domain.com
GIT_USER=nick


# CA name to go in the certificate. 
# !!! should include lab_domain value
LAB_BUILD_NET_SHORT_NAME=build
LAB_BUILD_DOMAIN=$LAB_BUILD_NET_SHORT_NAME.example.com
CA_FQDN=ca.$LAB_BUILD_DOMAIN

# That's it. 
# No need to change anything below here. 


#-------------------------

