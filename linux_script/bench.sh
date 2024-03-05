#!/bin/bash

type curl &>/dev/null
[[ $? != 0 ]] && echo "please instal curl" && exit 1
curl -Lso- bench.sh | bash

