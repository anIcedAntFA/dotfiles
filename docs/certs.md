# Corporate CA certificates — trust store restore

## Why

A few work systems present TLS certificates signed by a **private company CA**, not
a public one. Without that CA in the local trust store the connection is rejected,
so on a fresh install these certs are **step zero** — miss them and you can't even
download resources, reach internal GitHub, or log in to the AWS console.

There are currently three of them, all living in the system trust anchors:

| File (`/etc/ca-certificates/trust-source/anchors/`) | Needed for                                                                    |
| --------------------------------------------------- | ----------------------------------------------------------------------------- |
| `cert_vn_ssl_cert.crt`                              | Company SSL inspection CA — general external access **and** the [VPN](vpn.md) |
| `ap-southeast-2.signin.pem`                         | AWS **console** sign-in (SSO region cert)                                     |
| `awsapps-com.pem`                                   | AWS apps / WorkSpaces access                                                  |

> [!IMPORTANT]
> These are **certificates (public keys)**, not private keys — nothing here is
> cryptographically secret. But they identify the employer, and this repo is
> **public** (it feeds a blog), so the cert bytes are **never committed here.**
> They live in [gopass](gopass.md); this guide only describes the procedure.

## Where the bytes live: gopass

Store each cert as a secret in the gopass store (its own private repo). Because
they're plain PEM text, `gopass cat` handles them cleanly as file blobs. Do this
**once**, from a machine that still has the certs:

```sh
gopass cat work/certs/vn-ca      < /etc/ca-certificates/trust-source/anchors/cert_vn_ssl_cert.crt
gopass cat work/certs/aws-signin < /etc/ca-certificates/trust-source/anchors/ap-southeast-2.signin.pem
gopass cat work/certs/aws-apps   < /etc/ca-certificates/trust-source/anchors/awsapps-com.pem
gopass sync
```

For **why** these system secrets go in gopass rather than chezmoi, see
[ADR 0005](adr/0005-system-certs-in-gopass.md).

## Restoring on a fresh machine

The trust anchors are the **only source of truth** — the matching files under
`/etc/ssl/certs/*.pem` are symlinks that `update-ca-trust` regenerates. So the
whole procedure is: drop the anchors, run one command.

```sh
# 1. Write each cert back into the trust anchors (needs root):
gopass cat work/certs/vn-ca      | sudo tee /etc/ca-certificates/trust-source/anchors/cert_vn_ssl_cert.crt   >/dev/null
gopass cat work/certs/aws-signin | sudo tee /etc/ca-certificates/trust-source/anchors/ap-southeast-2.signin.pem >/dev/null
gopass cat work/certs/aws-apps   | sudo tee /etc/ca-certificates/trust-source/anchors/awsapps-com.pem        >/dev/null

# 2. Rebuild the system trust store:
sudo update-ca-trust

# 3. Verify one is trusted:
trust list | grep -i <your-ca-common-name>
```

After this, `/etc/ssl/certs/vn_ssl_cert.pem` (the path the [VPN](vpn.md) command
points at) exists again automatically.

> [!NOTE]
> `update-ca-trust` only picks up files under `trust-source/anchors/`. If you ever
> place a cert directly in `/etc/ssl/certs/`, it won't survive the next rebuild —
> put it in `anchors/` instead.

## Related

- [vpn.md](vpn.md) — the corporate VPN, which depends on the `vn-ca` cert
- [gopass.md](gopass.md) — the store these cert bytes live in
- [ADR 0005](adr/0005-system-certs-in-gopass.md) — why gopass, not chezmoi
- [ADR 0002](adr/0002-private-data-via-templates.md) — the in-repo no-encryption policy this is scoped against
