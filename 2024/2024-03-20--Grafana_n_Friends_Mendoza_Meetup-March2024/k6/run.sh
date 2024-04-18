#!/bin/bash -x
k6 run --vus 200 --duration 60s simple.js
