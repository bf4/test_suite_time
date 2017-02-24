Procore Test Suite Time
---

### Prerequisites:
1. To generate the graph, you need `gnuplot`.  `brew install gnuplot`
2. The repo must be set up to outut junit artifacts.  `procore/procore` is; Ididn't test anything else.
3.  You must have an API key from CircleCI to access the above artifacts.  Put it in the `CIRCLE_ENV` environmental variable.

### Usage
```bash
compile.rb [options] -r <repository>
    -r, --repository STR             Github repository, e.g. "procore/procore"
        --resolution FLOAT           Resolution for graph ouput (default 1.0)
    -g                               Gnuplot output graphing # of tests against time to execute
    -h, --help                       Display this screen
```

```bash
forrestfleming@fsf-procore test_suite_time master % CIRCLE_TOKEN=REDACTED ./procore_png.sh
tests.png written
```
![Output](/screenshot.png?raw=true "Example output")
