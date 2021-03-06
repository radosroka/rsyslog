#!/bin/bash
# added 2015-09-30 by singh.janmejay
# This file is part of the rsyslog project, released under ASL 2.0

uname
if [ `uname` = "FreeBSD" ] ; then
   echo "This test currently does not work on FreeBSD."
   exit 77
fi

echo ===============================================================================
echo \[lookup_table_no_hup_reload-vg.sh\]: test for lookup-table with HUP based reloading disabled with valgrind
. $srcdir/diag.sh init
generate_conf
add_conf '
lookup_table(name="xlate" file="xlate.lkp_tbl" reloadOnHUP="off")

template(name="outfmt" type="string" string="- %msg% %$.lkp%\n")

set $.lkp = lookup("xlate", $msg);

action(type="omfile" file=`echo $RSYSLOG_OUT_LOG` template="outfmt")
'
cp -f $srcdir/testsuites/xlate.lkp_tbl xlate.lkp_tbl
startup_vg
injectmsg  0 3
. $srcdir/diag.sh wait-queueempty
. $srcdir/diag.sh content-check "msgnum:00000000: foo_old"
. $srcdir/diag.sh content-check "msgnum:00000001: bar_old"
. $srcdir/diag.sh assert-content-missing "baz"
cp -f $srcdir/testsuites/xlate_more.lkp_tbl xlate.lkp_tbl
. $srcdir/diag.sh issue-HUP
. $srcdir/diag.sh await-lookup-table-reload
injectmsg  0 3
echo doing shutdown
shutdown_when_empty
echo wait on shutdown
wait_shutdown_vg
. $srcdir/diag.sh check-exit-vg
. $srcdir/diag.sh assert-content-missing "foo_new"
. $srcdir/diag.sh assert-content-missing "bar_new"
. $srcdir/diag.sh assert-content-missing "baz"
exit_test
