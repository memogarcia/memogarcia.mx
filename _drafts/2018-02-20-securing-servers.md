---
layout: post
title:  "Securing linux servers checklist"
date:   2018-02-20 12:20:38 +0100
categories:
---

1. SSH Configuration

`/etc/ssh/sshd_config`

1.1 Change SSH port

```bash
Port 12345
```

**Remember to change the security groups if there are**

1.2 Use strong Ciphers

Add or modify the following line:

```bash
Ciphers aes128-ctr,aes192-ctr,aes256-ctr
```

1.3 Use strong KexAlgorithms

```bash
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
```

1.4 Use strong MAC algorithms

```bash
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com
```
