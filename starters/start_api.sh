#!/bin/bash
docker run -d -it --rm -p 10100:10100 -p 8084:8084 -p 8889:8888 --name scilab6-docker-novnc avianinc/scilab6-docker-novnc:main