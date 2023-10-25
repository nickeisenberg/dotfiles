#!/bin/bash

# Lists all the installed packages that have no installed reverse dependencies.

# first line: will list all packages and their status
# second line: will get all the lines that end with installed
# third line: passes all of these intalled packages into apt-cache rdepends --installed
# fourth line: apt-cache rdepends --installed prodces outputs of the following form:
#                  package_name
#                  Reverse Depends:
#                    dependent 1
#                    dependent 2
#                    ---
#                    last dependent
#              So the fourth line reads the output in reverse order, will increment deps
#              by one if there is a white space and will print the line before 
#              Reverse Depends: if deps is 0. deps is 0 when there are no dependents.

function show_no_reverse_depends() {
    dpkg-query --show --showformat='${Package}\t${Status}\n' \
        | tac | awk '/installed$/ {print $1}' \
        | xargs apt-cache rdepends --installed \
        | tac | awk '{ if (/^ /) ++deps; else if (!/:$/) { if (!deps) print; deps = 0 } }'
}
