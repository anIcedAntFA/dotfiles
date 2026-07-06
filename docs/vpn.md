# Corporate VPN — GlobalProtect via `gpclient`

## Why

Work resources sit behind a Palo Alto **GlobalProtect** gateway. The official
client is GUI-only and closed; on Linux we use
[`globalprotect-openconnect`](https://github.com/yuezk/GlobalProtect-openconnect)
(`gpclient`), an OpenConnect-based reimplementation that does the SAML/browser
login and then hands off to `openconnect` for the tunnel. The packages are tracked
in [packages.md](packages.md).

## Prerequisites

1. **The company CA cert is installed.** The portal serves a cert signed by the
   internal CA, so it must be in the trust store first — see [certs.md](certs.md).
   The command below points OpenSSL at `/etc/ssl/certs/vn_ssl_cert.pem`, which
   only exists after `update-ca-trust` has run.
2. **Chrome is present** (`google-chrome`) — browser auth launches it for SSO.

## Connecting

A fish wrapper hides the long invocation. The portal host is a chezmoi template
var (`{{ .workVpnPortal }}`), so it's never hard-coded in this public repo:

```fish
vpn-connect          # defined in home/dot_config/fish/functions/vpn-connect.fish.tmpl
```

That expands to:

```sh
sudo -E SSL_CERT_FILE=/etc/ssl/certs/vn_ssl_cert.pem SSL_CERT_DIR=/etc/ssl/certs \
    gpclient --fix-openssl connect --browser chrome vpn.example.com
```

What each piece does:

| Piece                            | Role                                                                            |
| -------------------------------- | ------------------------------------------------------------------------------- |
| `sudo -E`                        | Root (needs to create the `tun` device) **and keep** the env vars.              |
| `SSL_CERT_FILE` / `SSL_CERT_DIR` | Point OpenSSL at the company CA so the portal cert validates.                   |
| `--fix-openssl`                  | Enables `UnsafeLegacyServerConnect` for the gateway's legacy TLS renegotiation. |
| `connect --browser chrome`       | Do the SAML login in Chrome, then bring up the tunnel.                          |
| `vpn.example.com`                | The portal host (real value from `chezmoi init`).                               |

A browser tab opens for SSO; after you authenticate, the terminal shows
`Connected to VPN` and the session lifetime (typically ~11h).

## Disconnecting

```sh
sudo gpclient disconnect
```

## What's normal in the logs

- **`Authentication failure: Invalid username or password` then a retry that
  succeeds** — the portal login attempt fails and `gpclient` falls back to
  _gateway_ auth, which works. Harmless.
- **`Server asked us to submit HIP report … VPN connectivity may be limited`** —
  the host-info check isn't submitted; the tunnel still comes up. Only a problem
  if the gateway _enforces_ HIP (it doesn't here).
- **`WEBKIT_DISABLE_DMABUF_RENDERER=1` / `LIBGL_ALWAYS_SOFTWARE=1`** — Wayland
  rendering fallbacks the client sets itself. Expected on niri.

## What it unlocks (e.g. AWS)

The VPN provides the **network path** to internal services. AWS console/app access
additionally needs its sign-in certs in the trust store — those are the
`aws-signin` / `aws-apps` certs in [certs.md](certs.md), independent of the tunnel.

## Related

- [certs.md](certs.md) — the CA cert this connection depends on
- [packages.md](packages.md) — the `globalprotect-openconnect` package

## References

- [GlobalProtect-openconnect](https://github.com/yuezk/GlobalProtect-openconnect)
- [OpenConnect](https://www.infradead.org/openconnect/)
