#!/bin/bash

if [ "" == "`ps waux|grep /Mail.app/|grep -v grep`" ]; then
    exit 0;
else
    exit 1;
fi

