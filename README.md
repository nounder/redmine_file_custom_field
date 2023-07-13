# Redmine File Custom field

This plugin enables creating File custom field allowing users to attach file to Redmine objects.

Files can be restricted to specified format or extension. With additional configuration, automatic
virus scanning is possible.

## Virus scanning

To enable trojan/virus scanning for uploaded files, install following packages:
`clamav clamav-scanner`

Then edit `/etc/clamd.d/scan.conf`:
```
Comentar Example
Descomentar TCPSocket 3310
Descomentar TCPAddr 127.0.0.1
Rodar como User root
systemctl start clamd.scan
systemctl enable clamd.scan
```

And enable the configuration:
```
ln -s /etc/clamd.d/scan.conf /etc/clamd.conf
```
