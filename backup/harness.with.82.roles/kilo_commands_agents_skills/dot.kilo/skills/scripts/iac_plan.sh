#!/usr/bin/env bash
# iac_plan.sh - `iac_plan.sh` runs OpenTofu or Terraform validate and plan, then policy and cost checks, and posts the plan to the issue
# STATUS: scaffold. Implement the logic, then remove the not_implemented call.
usage() { echo "Usage: iac_plan.sh [--dry-run] [args...]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
not_implemented "iac_plan.sh"
