#!/bin/bash

mkdir -p profile_results/private

find profile_results/ -name '*.html' -exec sed -i 's#file:////opt/matlab2014b/toolbox/matlab/codetools/##g' {} \;
cp /opt/matlab2014b/toolbox/matlab/codetools/*.css profile_results/
cp /opt/matlab2014b/toolbox/matlab/codetools/private/*.gif profile_results/private/
