#!/bin/bash

#docker run --pull=always -it -d --rm -p 22022:22 -p 8183:8183 -p 11223:11223 -p 17010:17010 --name zato-3.2-quickstart ghcr.io/zatosource/zato-3.2-quickstart
docker run -it -d --rm -p 22022:22 -p 8183:8183 -p 11223:11223 -p 17010:17010 --name zato-3.2-quickstart ghcr.io/zatosource/zato-3.2-quickstart