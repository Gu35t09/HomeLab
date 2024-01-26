
#ALL THE NECESSARY PACKAGES ARE INSTALLED BY ANSIBLE (vars.yml -> packages)

#------------------------------------------------------------------------------------------------------------------------------------------

# changing SMART stuff
sudo sed -i -e "s^#DEVICESCAN -a^DEVICESCAN -a -o on -S on -n standby,q -s (S/../.././02|L/../../6/03) -W 1,35,60 -m default^g" /etc/smartd.conf

#limit log filesize
sudo sed -i -e "s^#SystemMaxUse=^SystemMaxUse=50M^g" /etc/systemd/journald.conf

#this prevents docker container volumes to be falsely recognized as host system OS and added to boot menu. See https://wiki.archlinux.org/title/GRUB#Detecting_other_operating_systems
sudo sed -i -e "s^GRUB_DISABLE_OS_PROBER=false^GRUB_DISABLE_OS_PROBER=true^g" /etc/default/grub

# apply change
sudo grub-mkconfig

# enable sysRq key
# If the OS ever freezes completely, Linux allows you to use your keyboard to perform a graceful reboot or power-off, through combination of keys.
# This prevents any kind of filesystem damage or drive hardware damage, especially on HDDs.
# The following enables the key combination.
echo kernel.sysrq=1 | sudo tee --append /etc/sysctl.d/99-sysctl.conf

# Cronjobs are used to schedule maintenance tasks for backups, system cleanup and drive maintenance. These tasks require root. Root cronjob is used.
# Linux wants you to run each cronjob in different crontabs per user. However for a homeserver a single overview of cronjobs would be preferred.
sudo sh -c "echo LOGUSER=${USER} >> /etc/environment"

#Optimise power consumption ------------------------------------------------------------------------------------------------------------

[Unit]
Description=Powertop tunings

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/powertop --auto-tune

[Install]
WantedBy=multi-user.target
EOF
## Enable the service
sudo systemctl daemon-reload
sudo systemctl enable powertop.service
## Tune system now
sudo powertop --auto-tune
## Start the service
sudo systemctl start powertop.service

# SMTP notification -----------------------------------------------------------------------------------------------------------------------

sudo sh -c "echo default:mattia.vallortigara@protonmail.com >> /etc/aliases"

sudo tee -a /etc/ssmtp/ssmtp.conf &>/dev/null << EOF
#
# Config file for sSMTP sendmail
#
# The person who gets all mail for userids < 1000
# Make this empty to disable rewriting.
root=postmaster

# The place where the mail goes. The actual machine name is required no 
# MX records are consulted. Commonly mailhosts are named mail.domain.com
mailhub=mail.smtp2go.com

# Where will the mail seem to come from?
rewriteDomain=greyroom.net

# The full hostname
hostname=homelab-test

AuthUser=server@greyroom.net
AuthPass=X96gl74R8QaPmtI0
UseTLS=YES
UseSTARTTLS=YES

# Are users allowed to set their own From: address?
# YES - Allow the user to specify their own From: address
# NO - Use the system generated From: address
FromLineOverride=YES
EOF

# DOCKER ------------------------------------------------------------------------------------------------------------------------------

# Setup SRV directory for docker
sudo chown -R mattia /srv
sudo mkdir -p /srv/docker
sudo chown -R mattia /srv
# manually copy the docker compose file 

# Create network for internal services (like portaner, cockpit, film etc..)
docker network inspect frontend >/dev/null 2>&1 || \
    docker network create frontend

# Create network for exposed services (like vaultwarden, nextcloud)
docker network inspect proxy >/dev/null 2>&1 || \
    docker network create proxy

