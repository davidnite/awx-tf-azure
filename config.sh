sleep 5m

# Tower initial login
tower-cli config host http://localhost
tower-cli config verify_ssl false
tower-cli login admin --password password

# Change tower admin password
tower-cli user modify --username=admin --password=${awx_password}

# Azure Credential
tower-cli credential create --credential-type="Microsoft Azure Resource Manager" --organization=Default --name="Azure" --inputs='{"subscription":"${subscription_id}", "client":"${client_id}", "secret":"${client_secret}", "tenant":"${tenant_id}"}' --fail-on-found
# Scm Credential
tower-cli credential create --credential-type="Source Control" --organization=Default --name=SCM --inputs='{"username": "${scm_user}", "password": "${scm_pass}"}' --fail-on-found
# WinRM Credential
#tower-cli credential create --credential-type="Machine" --organization=Default --name=WinRM --inputs='{"username":"${domain_admin}", "password":"${domain_password}"}' --fail-on-found
# Create Azure inventory
tower-cli inventory create --name="Azure" --organization=Default --fail-on-found
tower-cli inventory_source create --source=azure_rm --name="Azure" --inventory="Azure" --credential="Azure" --fail-on-found
tower-cli schedule create --inventory-source="Azure" --name="AzureSchedule" --rrule "DTSTART:20181018T000000Z RRULE:FREQ=HOURLY;INTERVAL=1" --fail-on-found