# Rebuild and cut over for OS upgrades

The production and staging server runs Ubuntu 20.04 LTS, three LTS releases behind the 26.04 target (issue #1702).
Ubuntu only supports in-place upgrades from one LTS to the next, so reaching 26.04 in place would mean three
sequential `do-release-upgrade` runs on the live box serving both production and staging, with no rollback at any
step. We decided to build a fresh 26.04 instance from a new AMI and cut each environment over to it instead.

## Considered options

- Three sequential in-place release upgrades: no new instance needed, but three chances to break a live box and no
  way back from a bad step.
- Rebuild and cut over (chosen): the Terraform in `openaustralia/infrastructure` is already structured around AMI
  variables, and a fresh build forces the Ansible roles to prove they can produce a working server from scratch.

## Consequences

- Staging moves to the new instance first and acts as the rehearsal (see `CONTEXT.md`); production follows only once
  the worker, cron, mail, card screenshots and search have been verified there. No separate throwaway box.
- The server build itself lives in `openaustralia/infrastructure`, so this repository's changes must land together
  with a matching epic there.
