# Systemd service template

The `template/systemd/rescue-dhcp@.service.tmpl` is an example systemd unit for running the `rescue_dhcp.sh` script per-interface. Edit the `ExecStart` path to match your user's home path. To use it:

1. Copy the template to `/etc/systemd/system/rescue-dhcp@.service` and update the path.
2. Reload systemd: `sudo systemctl daemon-reload`
3. Start for a specific interface: `sudo systemctl start rescue-dhcp@enx9cebe869e600`
4. Enable if desired: `sudo systemctl enable --now rescue-dhcp@enx9cebe869e600`
