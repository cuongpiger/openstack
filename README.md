# 1. Prepare the environment
* Using Docker container as the environment:
  ```bash
  # workdir: here
  docker container run -it --rm --network host -v ./resources:/resources python:3.8 /bin/bash
  ```