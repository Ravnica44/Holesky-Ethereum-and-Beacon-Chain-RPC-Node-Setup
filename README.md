`nano /root/holesky-node/.env`

`chmod 600 /root/holesky-node/.env`


`openssl rand -hex 32 > /root/holesky-node/data/jwtsecret`

`chmod 600 /root/holesky-node/data/jwtsecret`


`nano /etc/systemd/system/geth-holesky.service`

`nano /etc/systemd/system/lighthouse-holesky.service`


`source .env`


`sudo ufw allow $GETH_HTTP_PORT/tcp`

`sudo ufw allow $GETH_WS_PORT/tcp`

`sudo ufw allow $LIGHTHOUSE_HTTP_PORT/tcp`

`sudo ufw allow $LIGHTHOUSE_WS_PORT/tcp`


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


```
curl -s -X POST -H "Content-Type: application/json" \
--data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
http://localhost:${HTTP_GETH_PORT} | jq
```

```
curl -s http://localhost:${HTTP_LIGHTHOUSE_PORT}/eth/v1/node/syncing | jq
```


