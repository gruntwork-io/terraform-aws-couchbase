# Couchbase Commons

This directory contains a number of Bash scrips that contain common function used throughout the Couchbase modules.




## Usage

All of the code in this module follows the [Google Bash Style Guide](https://google.github.io/styleguide/shell.xml),
so all of the code is defined in reusable functions. To "import" the functions into your own Bash scripts, you can
use the `source` command:

```bash
source "couchbase-common.sh"

# Now you can use functions from within couchbase-common.sh
if cluster_is_initialized "127.0.0.1" "admin" "password"; then
  echo "Cluster is initialized!"
fi
``` 