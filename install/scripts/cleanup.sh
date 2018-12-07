#!/bin/bash
set -e
set -x

yum clean
rm -rf /scripts
rm -rf /tmp/* /var/tmp/*
rm -rf /var/lib/apt/lists/*
