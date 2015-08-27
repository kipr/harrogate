#!/bin/sh

GIT=git
HG=hg
SVN=svn

update_git()
{
	echo "--------------------------------------------------------------------------------"
	echo "Update ${2}"
	local repo=$1
	local name=$2
	if [ ! -d $2 ]; then
		${GIT} clone ${1}
	else
		local wd=${PWD}
		cd "$2"
		echo "${GIT} pull"
		${GIT} pull
		cd ${wd}
	fi
	if [ "$?" -ne "0" ]; then
		echo "Updating git repository ${1} failed."
		exit 1
	fi
	echo "${2} is now up-to-date."
}

update_tar()
{
	echo "--------------------------------------------------------------------------------"
	echo "Update ${2}"
	local repo=$1
	local name=$2
	if [ ! -d ${2}* ]; then
		curl -L "${repo}" | tar xz
		if [ "$?" -ne "0" ]; then
			echo "Updating tar repository ${repo} failed."
			exit 1
		fi
	fi
	echo "${2} is now up-to-date."
}


update_svn()
{
	echo "--------------------------------------------------------------------------------"
	echo "Update ${2}"
	local repo=$1
	local name=$2
	if [ ! -d $2 ]; then
		${SVN} co ${1}
	else
		local wd=${PWD}
		cd "$2"
		${SVN} up
		cd ${wd}
	fi
	if [ "$?" -ne "0" ]; then
		echo "Updating svn repository ${1} failed."
		exit 1
	fi
	echo "${2} is now up-to-date."
}

#########################
# Fetch !              #
#########################

update_tar http://sourceforge.net/projects/boost/files/boost/1.58.0/boost_1_58_0.tar.bz2/download boost_1_58_0
update_git https://github.com/mongodb/libbson.git libbson
update_git https://github.com/kipr/daylite.git daylite
update_tar http://download.sourceforge.net/libpng/libpng-1.6.18.tar.gz libpng-1.6.18
update_git https://github.com/kipr/libaurora.git libaurora
update_git https://github.com/kipr/harrogate.git harrogate
update_tar https://nodejs.org/dist/v0.10.40/node-v0.10.40-darwin-x64.tar.gz node-v0.10.40-darwin-x64
