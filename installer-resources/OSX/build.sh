#
#  Copyright 2012 KISS Institute for Practical Robotics
#
#  This file is part of the KISS Platform (Kipr's Instructional Software System).
#
#  The KISS Platform is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 2 of the License, or
#  (at your option) any later version.
#
#  The KISS Platform is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with the KISS Platform.  Check the LICENSE file in the project root.
#  If not, see <http://www.gnu.org/licenses/>.

#!/bin/sh

APP_MAJOR_VERSION="1"
APP_MINOR_VERSION="0"
BUILD_NUMBER="28"

VERSION="${APP_MAJOR_VERSION}.${APP_MINOR_VERSION}.${BUILD_NUMBER}"

BUILD=${PWD}/build
mkdir -p ${BUILD}

INSTALL=/opt/KIPR/KIPR-Software-Suite-${VERSION}/shared
mkdir -p ${INSTALL}

build_boost()
{
	echo "--------------------------------------------------------------------------------"
	echo "Build ${1}"
	local folder=$1
	local install=$2
	local options=$3
	local wd=${PWD}
	cd "${wd}/${folder}"
	echo ".bootstrap.sh ${options}"
	./bootstrap.sh ${options}
	if [ "$?" -ne "0" ]; then
		echo "bootstrap ${folder} failed."
		exit 1
	fi
	./b2 -j4
	if [ "$?" -ne "0" ]; then
                echo "./b2 for ${1} failed."
                exit 1
        fi

        if [[ "${install}" -eq "1" ]]; then
                ./b2 install
                if [ "$?" -ne "0" ]; then
                        echo "./b2 install for ${1} failed."
                        exit 1
                fi
        fi
        cd "${wd}"
}

build_autotools()
{
	echo "--------------------------------------------------------------------------------"
	echo "Build ${1}"
	local folder=$1
	local install=$2
	local options=$3
	local wd=${PWD}
	cd "${wd}/${folder}"
	echo "./configure ${options}"
	./configure ${options}
	if [ "$?" -ne "0" ]; then
		echo "cmake for ${1} failed."
		exit 1
	fi
	make -j4
	if [ "$?" -ne "0" ]; then
		echo "make for ${1} failed."
		exit 1
	fi
	
	if [[ "${install}" -eq "1" ]]; then
		make install
		if [ "$?" -ne "0" ]; then
			echo "make install for ${1} failed."
			exit 1
		fi
	fi
	cd "${wd}"
}

build_cmake()
{
	echo "--------------------------------------------------------------------------------"
	echo "Build ${1}"
	local folder=$1
	local install=$2
	local options=$3
	mkdir -p ${BUILD}/${folder}
	local wd=${PWD}
	cd ${BUILD}/${folder}
	if [[ $(uname -s) == MINGW* ]] ;
	then
		QTDIR=/c/Qt cmake ${wd}/${folder} -G "MSYS Makefiles" "-DDIRECTX=/c/Program Files/Microsoft DirectX SDK (June 2010)" --no-warn-unused-cli ${options}
	else
		cmake ${wd}/${folder} ${options}
	fi
	if [ "$?" -ne "0" ]; then
		echo "cmake for ${1} failed."
		exit 1
	fi
	make -j4
	if [ "$?" -ne "0" ]; then
		echo "make for ${1} failed."
		exit 1
	fi
	
	if [[ "${install}" -eq "1" ]]; then
		make install
		if [ "$?" -ne "0" ]; then
			echo "make install for ${1} failed."
			exit 1
		fi
	fi
	cd -
}

build_make()
{
	local folder=$1
	local install=$2
	local options=$3
	local wd=${PWD}
	
	cd ${folder}
	make -j1 ${options}
	if [ "$?" -ne "0" ]; then
		echo "make for ${1} failed."
		exit 1
	fi
	
	if [[ "${install}" -eq "1" ]]; then
		make ${options} install
		if [ "$?" -ne "0" ]; then
			echo "make install for ${1} failed."
			exit 1
		fi
	fi
	cd ${wd}
}

run_npm()
{
	local folder=$1
	local npm=$2
	local cmd=$3
	local wd=${PWD}

	cd ${folder}
	${npm} ${cmd}
	if [ "$?" -ne "0" ]; then
		echo "npm install for ${1} failed."
		exit 1
	fi
	cd ${wd}
}

#########################
# Build!                #
#########################

build_boost boost_1_58_0 1 "--prefix=${BUILD}"
build_cmake libbson 1 "-DCMAKE_INSTALL_PREFIX=${INSTALL}"
build_cmake daylite 1 "-DBOOST_INCLUDE_DIR=${BUILD}/include -DCMAKE_LIBRARY_PATH=${BUILD}/lib:{INSTALL}/lib -DLIBBSON_INCLUDE_DIR=${INSTALL}/include/libbson-1.0 -DCMAKE_INSTALL_PREFIX=${INSTALL}"
build_cmake libpng-1.6.18 1 "-DCMAKE_INSTALL_PREFIX=${INSTALL}"
build_cmake libaurora 1 "-DCMAKE_INCLUDE_PATH=${INSTALL}/include -DCMAKE_LIBRARY_PATH=${INSTALL}/lib -DLIBBSON_INCLUDE_DIR=${INSTALL}/include/libbson-1.0 -DCMAKE_INSTALL_PREFIX=${INSTALL}"
run_npm harrogate "${PWD}/node-v0.10.40-darwin-x64/bin/npm" "install"
run_npm harrogate "${PWD}/node-v0.10.40-darwin-x64/bin/npm" "run compile"

cp -r harrogate "${INSTALL}/../"
cp -r node-v0.10.40-darwin-x64/* "${INSTALL}/"

echo "#!/usr/bin/env bash

cd ${INSTALL}/../harrogate/

${INSTALL}/bin/node server.js" > "${INSTALL}/../Start KISS IDE Server.command"
chmod a+x "${INSTALL}/../Start KISS IDE Server.command"

exit 0
