# godir

[![Build Status](https://github.com/perlorg/www.pm.org/actions/workflows/godir.yml/badge.svg)](https://github.com/perlorg/www.pm.org/actions/workflows/godir.yml)

godir is a server that reads `perl_mongers.xml`, and serves redirects if the
`<web>` element points away from pm.org.

## Container Image

```
ghcr.io/perlorg/godir
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | HTTP port to listen on |
| `ROOT` | `.` | Directory containing `perl_mongers.xml` |
| `LOG_LEVEL` | `INFO` | Logging verbosity: DEBUG, INFO, WARN, ERROR |

## Endpoints

| Path | Description |
|------|-------------|
| `/` | Redirect handler - extracts subdomain and redirects to group's web URL |
| `/health` | Health check - returns `200 OK` with body "ok" |

## Running

```bash
# Local development
ROOT=.. go run .

# Docker
docker run -p 8080:8080 -v /path/to/perl_mongers.xml:/perl_mongers.xml -e ROOT=/ ghcr.io/perlorg/godir
```

## Config

Kubernetes config lives in the perl k8s repo.
