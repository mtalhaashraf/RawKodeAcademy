#!/usr/bin/env bash
set -xeuo pipefail

curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /root/.bashrc
