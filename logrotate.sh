touch /etc/rsyslog.d/10-omf-sfa.conf
echo "
if $programname == 'ruby' then {
	/var/log/omf-sfa.log
	~
}" >> /etc/rsyslog.d/10-omf-sfa.conf


touch /etc/rsyslog.d/10-omf-rc.conf
echo "
if $programname == 'omf-rc' then {
	/var/log/omf-rc.log
	~
}" >> /etc/rsyslog.d/10-omf-rc.conf


touch /etc/logrotate.d/omf_sfa
echo "/var/log/omf_sfa.log {
daily
rotate 0
compress
copytruncate
}" >> /etc/logrotate.d/omf_sfa


touch /etc/logrotate.d/omf_rc
echo "/var/log/omf_rc.log {
daily
rotate 0
compress
copytruncate
}" >> /etc/logrotate.d/omf_rc

(crontab -l 2>/dev/null; echo "0 12   * /usr/sbin/logrotate --force /etc/logrotate.d/omf_sfa >/dev/null 2>$") | crontab -

(crontab -l 2>/dev/null; echo "0 12   * /usr/sbin/logrotate --force /etc/logrotate.d/omf_rc >/dev/null 2>$") | crontab -
