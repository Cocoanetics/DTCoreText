#!/bin/bash

source script/env.sh
declare -r gcov_dir="${OBJECT_FILE_DIR_normal}/${CURRENT_ARCH}/"

## ======

generateGcov()
{
	#  doesn't set output dir to gcov...
	#cd "${gcov_dir}"
	echo "---- dir: ${gcov_dir}"

	find "${gcov_dir}" -name "*.gcda" -exec gcov-4.2 {} -o "${gcov_dir}" \;

	#cd -
}

copyGcovToProjectDir()
{
	cp -r "${gcov_dir}" gcov
}

removeGcov()
{
	rm -r gcov
}

main()
{
# generate + copy
	generateGcov
	copyGcovToProjectDir
# post
	coveralls ${@+"$@"}
# clean up
	removeGcov
}

main ${@+"$@"}
