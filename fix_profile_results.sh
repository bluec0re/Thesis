#!/bin/bash
# copies the files needed to view the matlab profiling results

DIR="$1"
if [[ "x$DIR" == "x" ]]
then
    DIR="profile_results"
fi

echo "Fixing $DIR"

mkdir -p "$DIR/private"

find "$DIR/" -name '*.html' -exec sed -i 's#file:////opt/matlab2014b/toolbox/matlab/codetools/##g' {} \;
cp /opt/matlab2014b/toolbox/matlab/codetools/*.css "$DIR"/
cp /opt/matlab2014b/toolbox/matlab/codetools/private/*.gif "$DIR/private/"
