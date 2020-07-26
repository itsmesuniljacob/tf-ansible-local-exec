# Terraform with Ansible

Since Terraform did not have native Ansible provisioner support (at the time of writing this), had to find a way to spawn infra and configure VM using Ansible.

Below are the different ways to use Terraform with Ansible

## Use `local-exec`

When using `local-exec` these does not wait for the instance to launch. So mostly we would get connection error, since no machine is listening.

As a workaround, we force the Terraform to wait until connection to instance is established using `remote-exec` . This can be a simple echo of `Hello World`. Then will run a `local-exec` command to execute the `ansible-playbook` command on the same machine.
