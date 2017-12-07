#!/bin/bash

echo 'activating root login in ssh config'
sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config

echo 'restarting sshd service'
sudo service sshd restart

echo 'copying vagrant authorized_key file'
sudo cp -r ~vagrant/.ssh /root/.ssh

echo 'set owner for root .ssh'
sudo chown root. /root/.ssh
