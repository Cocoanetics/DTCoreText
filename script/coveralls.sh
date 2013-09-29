#!/bin/bash

source script/env.sh
declare -r gcov_dir="${OBJECT_FILE_DIR_normal}/${CURRENT_ARCH}/"

## ======

generateGcov()
{
	#  doesn't set output dir to gcov...
	cd "${gcov_dir}"
	for file in *.gcda
	do
		gcov "${file}" -o "${gcov_dir}"
	done
	cd -
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
	coveralls -e Core/Externals -e Core/Test ${@+"$@"}
# clean up
	removeGcov
}

main ${@+"$@"}
