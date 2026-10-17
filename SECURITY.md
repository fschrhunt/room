# Security

`room` never handles your SMB password. It mounts through Finder's
`mount volume`, so the credential lives in the login keychain and is used by
macOS, not by this tool. Config files contain only the server, share, user and
mount point and are written mode `0600`; logs contain only mount attempts.

## Reporting

Open a private security advisory on GitHub, or email the maintainer listed on the
GitHub profile. Please do not open a public issue for a vulnerability.
