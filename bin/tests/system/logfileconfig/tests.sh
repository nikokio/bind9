#!/bin/sh
#
# Copyright (C) 2011-2013  Internet Systems Consortium, Inc. ("ISC")
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND ISC DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS.  IN NO EVENT SHALL ISC BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
# OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

# $Id$

SYSTEMTESTTOP=..
. $SYSTEMTESTTOP/conf.sh
THISDIR=`pwd`
CONFDIR="ns1"
PLAINCONF="${THISDIR}/${CONFDIR}/named.plain"
DIRCONF="${THISDIR}/${CONFDIR}/named.dirconf"
PIPECONF="${THISDIR}/${CONFDIR}/named.pipeconf"
SYMCONF="${THISDIR}/${CONFDIR}/named.symconf"
PLAINFILE="named_log"
DIRFILE="named_dir"
PIPEFILE="named_pipe"
SYMFILE="named_sym"
PIDFILE="${THISDIR}/${CONFDIR}/named.pid"
myRNDC="$RNDC -c ${THISDIR}/${CONFDIR}/rndc.conf"
myNAMED="$NAMED -c ${THISDIR}/${CONFDIR}/named.conf -m record,size,mctx -T nosyslog -d 99"

# Stop the server and run through a series of tests with various config
# files while controlling the stop/start of the server.
# Have to stop the stock server because it uses "-g"
#
$PERL ../stop.pl . ns1

cd $CONFDIR

$myNAMED > /dev/null 2>&1

if [ $? -ne 0 ]
then
	echo "I:failed to start $myNAMED"
	echo "I:exit status: $status"
	exit $status
fi

status=0

echo "I:testing log file validity (only plain files allowed)"

# First run with a known good config.
kill `cat named.pid`
echo > $PLAINFILE
cp $PLAINCONF named.conf
#$myRNDC reconfig
$myNAMED > /dev/null 2>&1
if [ $? -ne 0 ]
then
	echo "I: $myNAMED failed to start (UNEXPECTED)"
	echo "I:exit status: 2"
	exit 2
fi

grep "reloading configuration failed" named.run > /dev/null 2>&1
if [ $? -ne 0 ]
then
	echo "I: testing plain file succeeded"
	kill `cat named.pid`
else
	echo "I: testing plain file failed (unexpected)"
	echo "I:exit status: 1"
	exit 1 
fi

# Now try directory, expect failure
echo "I: testing directory as log file"
echo > named.run
mkdir -p $DIRFILE >/dev/null 2>&1
if [ $? -eq 0 ]
then
	cp $DIRCONF named.conf
	echo > named.run
	#$myRNDC reconfig
	$myNAMED > /dev/null 2>&1
	if [ $? -eq 0 ]
	then
		echo "I: $myNAMED successfully started (UNEXPECTED)"
		echo "I:exit status: 2"
		exit 2
	fi
	grep "configuring logging: invalid file" named.run > /dev/null 2>&1
	if [ $? -ne 0 ]
	then
		echo "I: testing directory as file succeeded (UNEXPECTED)"
		echo "I:exit status: 1"
		exit 1
	else
		echo "I: testing directory as log file failed (expected)"
	fi
else
	echo "I: skipping directory test (unable to create directory)"
fi

# Now try pipe file, expect failure
echo "I: testing pipe file as log file"
echo > named.run
mkfifo $PIPEFILE >/dev/null 2>&1
if [ $? -eq 0 ]
then
	cp $PIPECONF named.conf
	echo > named.run
	#$myRNDC reconfig
	$myNAMED > /dev/null 2>&1
	if [ $? -eq 0 ]
	then
		echo "I: $myNAMED successfully started (UNEXPECTED)"
		echo "I:exit status: 2"
		exit 2
	fi
	grep "configuring logging: invalid file" named.run > /dev/null 2>&1
	if [ $? -ne 0 ]
	then
		echo "I: testing pipe file as log file succeeded (UNEXPECTED)"
		echo "I:exit status: 1"
		exit 1
	else
		echo "I: testing pipe file as log file failed (expected)"
	fi
else
	echo "I: skipping pipe test (unable to create pipe)"
fi

# Now try symlink file to plain file, expect success 
echo "I: testing symlink to plain file as log file"
# Assume success
status=0
echo > named.run
echo > $PLAINFILE
ln -s $PLAINFILE $SYMFILE >/dev/null 2>&1
if [ $? -eq 0 ]
then
	cp $SYMCONF named.conf
	echo > named.run
	#$myRNDC reconfig
	$myNAMED > /dev/null 2>&1
	if [ $? -ne 0 ]
	then
		echo "I: $myNAMED failed to started (UNEXPECTED)"
		echo "I:exit status: 2"
		exit 2
	fi
	grep "reloading configuration failed" named.run > /dev/null 2>&1
	if [ $? -ne 0 ]
	then
		echo "I: testing symlink to plain file succeeded"
		kill `cat named.pid`
	else
		echo "I: testing symlink to plain file failed (unexpected)"
		echo "I:exit status: 1"
		exit 1
	fi
else
	echo "I: skipping symlink test (unable to create symlink)"
fi

echo "I:exit status: $status"
exit $status
