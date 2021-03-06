# Display a diff of 2 git commits
function diffdiff() {
    diff -u <(git show "$1") <(git show "$2")
}

# Given a test run output (e.g. CI console.html), display the names of failed
# tests
function failed_tests() {
    awk '$NF == "FAILED" && $(NF-1) == "..." {print $(NF-3)}' < "$1"
}

# Run a single test against all initialised venvs in the .tox directory
function testone() {
    if [ ! -d .tox ]; then
        >&2 echo .tox directory does not exist
        return 1
    fi

    envs=$(shopt -s nullglob;
           for env in .tox/py[0-9][0-9]; do
               [ -f $env/bin/python ] && echo $env;
           done)
    if [ -z "$envs" ]; then
        >&1 echo Did not find any pyXX venvs in .tox
        return 1
    fi

    for env in $envs; do
        echo Using $(basename $env)

        $env/bin/python -m testtools.run "$@"
        if [ $? != 0 ]; then
            return $?
        fi
    done
}

# Run a single test using a pre-created py27 tox environment
function testone27() {
    .tox/py27/bin/python -m testtools.run "$@"
}

# Run a single test using a pre-created py34 tox environment
function testone34() {
    .tox/py34/bin/python -m testtools.run "$@"
}

function _tox_staged(){
    tests=""
    for test in $(git diff --cached --name-only | grep tests); do 
        t=$(echo $test | sed 's/\//\./g' | sed 's/\.py//g')
        tests+=" ${t}"; 
    done
    tox -e py27 $tests
}

function _tox_last(){                                                         
    touched_tests=$(git diff-tree --no-commit-id --name-only -r HEAD | grep tests)
    tests=""
    for test in $touched_tests; do t=$(echo $test | sed 's/\//\./g' | sed 's/\.py//g'); tests+=" ${t}"; done
    tox -e py27 $tests
}

# Lovingly stolen from:
#   http://stackoverflow.com/questions/1527049/join-elements-of-an-array
function _join_by { local IFS="$1"; shift; echo "$*"; }

# Fetch a number of log files from a ci run using curl
# Usage: ci_log_fetch http://logs.openstack.org/.../f829785/logs/ n-api n-vol
function ci_log_fetch() {
    url=$1
    shift

    curl --compressed "$url/screen-{"$(_join_by , $*)"}.txt.gz" -o "#1.log"
}
