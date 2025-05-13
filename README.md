`nano /root/holesky-node/.env`

`chmod 600 /root/holesky-node/.env`

`nano /etc/systemd/system/geth-holesky.service`

`nano /etc/systemd/system/lighthouse-holesky.service`

`systemctl daemon-reload`

`systemctl enable geth-holesky.service`

`systemctl enable lighthouse-holesky.service`

`systemctl start geth-holesky.service`

`systemctl start lighthouse-holesky.service`

`systemctl restart geth-holesky.service`

`systemctl restart lighthouse-holesky.service`

`systemctl status geth-holesky.service`

`systemctl status lighthouse-holesky.service`

`journalctl -u geth-holesky.service -f`

`journalctl -u lighthouse-holesky.service -f`

`systemctl stop geth-holesky.service`

`systemctl stop lighthouse-holesky.service`

`systemctl disable geth-holesky.service`

`systemctl disable lighthouse-holesky.service`
