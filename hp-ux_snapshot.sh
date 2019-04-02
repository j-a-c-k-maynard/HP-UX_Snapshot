#!/usr/bin/ksh
#
# @(#) /usr/contrib/bin/snapshot $Revision 0.3.0 $ Date: 98/03/31 08:00:00 $
##########################################################################
#                                                                        #
#   Program:   snapshot ver 3.0, HP-UX System Documentation Tool         #
#                                                                        # 
#    Author:   Jack Maynard,                                             # 
#                                                                        #
#              Please direct comments, suggestions and/or bug-fixes      #
#              to jack@maynard.com                                       #
#                                                                        #
# DISCLAIMER:  This script is a contributed utility, no official         # 
#              support for it will be provided.                          # 
#                                                                        #
#  Important:  If you are running on a 9.x O/S, please configure         #
#              the shell on line 1 to /bin/ksh.  For 10 & 11 systems     #
#              please use /usr/bin/ksh. This assumes no transition links.#
#                                                                        #
#  Important:  You must configure the customer variables section         # 
#              located at line 112 for this script to run correctly,     #
#              or use the command line argument -i for interactive.      #
#                                                                        #
#   Xvg Note:  This script collects data using VgCollect for Xvg.        #
#              You may open the output of this script directly by the    #
#              Xvg application without need to trim other data within    #
#              the script.  Save output of script to <filename> then     #
#              load it into Xvg with the command Xvg <filename>.  Xvg    #
#              will ignore all other non-relevant data within the file   #
#              and display the Motif LVM data.                           #
#                                                                        #
#   ABSTRACT:  This script is known to run on HP-UX 9.x, 10.x, & 11.x    #
#              O/S versions. It gathers system configuration             #
#              information for use by engineers needing comprehensive    #
#              system documentation. It's output can be configured       #
#              to log to a file or to  e-mail to a distribution list,    #
#              or both.                                                  #
#                                                                        #
#              The intent was to find the best support scripts and       #
#              incorporate them into one cohesive script.  With          #
#              apologies to the various script authors, it               #
#              incorporates the best of the following scripts:           #
#                                                                        #
#                     * VgCollect ver. 2.04 (collect script for Xvg)     #
#                       Author: Didier Lecardez                          #
#                                                                        #
#                     * capture ver. 3.6                                 #
#                       Author: Dave Olker                               #
#                                                                        #
#                     * LVMcollect ver. 4.0   (10.x)                     #
#                       Author: Peter Van Giel                           #
#                                                                        #
#                     * LVMcollect ver. 3.02  (9.x)                      #
#                       Author: Peter Van Giel                           #
#                                                                        #
#     Modifications:                                                     #
#									 #
#                     03/31/98  ver 3.0                                  #
#									 #
#                     * ported to hp-ux 11.x                             #
#									 #
#                     * updated VgCollect script to ver 2.04 for 11.x    #
#									 #
#                     * added Table of Contents to output                #
#                                                                        #
#                                                                        #
#                     08/26/97  ver 2.03                                 #
#                                                                        #
#                     * incorporated VgCollect script to enable          #
#                       capture of customer's LVM configuration          #
#                       for import into XVG                              #
#                                                                        #
#                     * fixed a bug that caused invalid diskinfo         #
#                       checks on softlink device files created          #
#                       by HP transition links for software              #
#                       compatibility between 9.x and 10.x.              #
#                                                                        #
#                     * added variable to choose whether to include      #
#                       password and group files in output.  Some        #
#                       customers are sensitive (and rightly so) to      #
#                       sending un-encrypted password info across the    #
#                       internet.                                        #   
#                                                                        #
#                     06/03/96  ver 2.02                                 #
#                                                                        #
#                     * enhanced OS version lookup to include            #
#                       release level, ie: 9.04.3b                       #
#                                               ^^                       #
#                                                                        #
#                     * enhanced error messages when command             #
#                       is not found on system                           #
#                                                                        #
#                     * sorted patch output by type, ie CO,KL            #
#                                                                        #
#                     * fixed path to diags for DUI                      #
#                                                                        #
#                     * added variable to turn on or off collection      #
#                       of network rc scripts -- too verbose             #
#                                                                        #
#                     03/04/96  ver 2.01                                 #
#                                                                        #
#                     * 9.x systems called wrong mailer - fixed          #
#                                                                        #
#                     02/23/96  ver 2.0                                  #
#                                                                        #
#                     * updated capture to ver 3.6                       #
#                                                                        #
#                     * updated LVMcollect to ver 4.0 & 3.02             #
#                                                                        #
#                     * removed shar'd logfile collection from capture   #
#                                                                        #
#                     * removed LVM section from capture                 #
#                                                                        #
#                     * added configurable printer variable              #
#                                                                        #
##########################################################################

##########################################################################
#                      START OF CUSTOMER VARIABLES                       # 
##########################################################################
# Note: configure these variables to run in non-interactive mode (cron)  #
# For yes or no answers, please use "YES" or "NO".

# Company name of customer.
CUST_NAME=""

# System Handle or support identifier.
SYS_ID=""

# Do you wish to mail the output file?   
MAIL_FILE=""   

# Customer e-mail address for output file. 
CUST_EMAIL="" 

# Alternate e-mail address for support personel.  
ALT_EMAIL="" 

# Directory where you wish to save output.
SAVE_DIR=""

# Do you want to include sensitive files (like passwords)? 
SENSITIVE_FILES="YES" 

##########################################################################
#                        END OF CUSTOMER VARIABLES                       # 
##########################################################################


##########################################################################
#                           PROGRAM VARIABLES                            #
##########################################################################

PATH=:/usr/contrib/bin:/etc:/usr/etc:/sbin:/usr/sbin:/usr/sbin/diag:/usr/diag/bin:/bin:/usr/bin:/usr/lib:/usr/sam/lbin:/usr/sam/bin:/etc/netbios:/usr/net/servers/lanman/bin:/usr/netware/bin:/opt/netware/bin:/usr/etc/yp:/etc/net/osi/ots:/usr/lib/netsvc:/usr/lib/netsvc/yp:/system/TOOL:/usr/local/bin:/usr/lbin/sysadm:/opt/lmu/netbios/bin:/opt/lmu/lanman/bin:/opt/lmx/lanman/bin
export PATH

SCRIPT_NAME=`basename $0`

HOST_NAME=$(hostname)

OS_VERSION=$(uname -r | awk -F. '{print $2}')

SPU_ID=$(uname -i)

USER_LICENSE=$(uname -l | awk '{print $1}')

VER="3.0" 

if [ $OS_VERSION -lt 10 ]
then
    DNS_DOMAIN=$(domainname)
else
    DNS_DOMAIN="$(nslookup $HOST_NAME |grep Name |grep -v Server | cut -d"." -f2-6)"
fi

##########################################################################
#                           PROGRAM FUNCTIONS                            #
##########################################################################

get_opts()
{

if (($# == 0))
then
 usage
  exit 1
fi

while getopts :iachlsuxH arguments
do
  case $arguments in
    a) redirect
       summary_info 
       capture
       lvm_info
       print_footer
       vgcollect;;
    c) redirect
       summary_info 
       capture
       print_footer;;
    h) print_help
        exit 1;;
    i) interact;;
    l) redirect
       lvm_info
       print_footer;;
    s) redirect
       summary_info
       print_footer;;
    x) redirect
       vgcollect;;
    u) usage
         exit -1;;
    *) print "\n${half}Invalid option${off}\n" 
       usage
       exit -1;;
  esac
done
} 

print_help()
{
cat << EOF | more

Please execute '$SCRIPT_NAME -u' for usage information.

EOF
}


usage()
{
clear
cat << EOF | more
$SCRIPT_NAME $VER by Jack Maynard (jack_maynard@hp.com)

Usage:  ${SCRIPT_NAME} [-a] [-i] [-H]
        ${SCRIPT_NAME} [-cdilsxH]
        ${SCRIPT_NAME} [-h]

        -a collect all of the following options
        -c collect system configuration data
        -d collect diagnostic (hardware map) data
        -l collect Logical Volume Manager data
        -s collect summary (quick) system data
        -x collect XVG (vgcollect) data

        -i interactive mode - prompts for runtime variables
        -h displays detailed help message
        -H send output to logfile in HTML format (default is ascii)

Note:  If you wish to run this script non-interactively, 
       please modify the variables at line 112 of the script.
       Otherwise use the '-i' flag and the script will prompt
       you for the proper information.

EOF
}


interact()
{

part_1()
{
print
print "Enter Customer Name > \c"
read CUST_NAME
print "You entered "$CUST_NAME".  Is this correct? (y/n)> \c"
read ANSWER

while [[ $ANSWER != "y" ]]
do
print
print "Enter Customer Name > \c"
read CUST_NAME
print "You entered: "$CUST_NAME"  Is this correct? (y/n)> \c"
read ANSWER
done

print
}

part_2()
{
print "Enter System Handle > \c"
read SYS_ID
print "You entered: "$SYS_ID"  Is this correct? (y/n)> \c"
read ANSWER

while [[ $ANSWER != "y" ]]
do
print
print "Enter System Handle > \c"
read SYS_ID
print "You entered: "$SYS_ID"  Is this correct? (y/n)> \c"
read ANSWER
done

print
}

part_3()
{
print "Please enter where you want output file saved ie: /tmp> \c"
read SAVE_DIR
print "You entered: "$SAVE_DIR"  Is this correct? (y/n)> \c"
read ANSWER

while [[ $ANSWER != "y" ]]
do
print
print "Please enter where you want output file saved ie: /tmp> \c"
read SAVE_DIR
print "You entered: "$SAVE_DIR"  Is this correct? (y/n)> \c"
read ANSWER
done

print
}

part_4()
{
print "Do you wish to mail the output file? (y/n)> \c"
read MAIL_FILE

if [[ $MAIL_FILE = "y" ]]
then
print
print "Please enter a valid e-mail address, ie: root or root@xyz.com> \c"
read CUST_EMAIL
print "You entered: "$CUST_EMAIL"  Is this correct? (y/n)> \c"
read ANSWER

while [[ $ANSWER != "y" ]]
do
print
print "Please enter a valid e-mail address, ie: root or root@xyz.com> \c"
read CUST_EMAIL
print "You entered: "$CUST_EMAIL"  Is this correct? (y/n)> \c"
read ANSWER
done
fi
print
}

part_5()
{
ANSWER=""
print "You chose:"
print  
print "   1.  Customer Name  :  $CUST_NAME"
print "   2.  System Handle  :  $SYS_ID"
print "   3.  Save directory :  $SAVE_DIR"

if [[ $MAIL_FILE != "n" ]]
then
print "   4.  e-mail address :  $CUST_EMAIL"
fi

print
print "Is the above information correct? (y/n)> \c"
read ANSWER

while [[ $ANSWER != "y" ]]
do
print "Enter the number of the item you wish to change > \c"
read NUMBER 

if [[ $NUMBER = "1" ]]
then
part_1
part_5
fi

if [[ $NUMBER = "2" ]]
then
part_2
part_5
fi

if [[ $NUMBER = "3" ]]
then
part_3
part_5
fi

if [[ $NUMBER = "4" ]]
then
part_4
part_5
fi

done

print
}

part_1
part_2
part_3
part_4
part_5

}  # end of interact function


vgcollect()
{

#
#  This function runs the VgCollect 2.04 script for import into XVG
#
print "*******************************************************************************"  
print "*******                  START OF VGCOLLECT for XVG                     *******"
print "*******************************************************************************"
echo

OS=`uname -r | cut -d'.' -f2`

typeset -i pvnum
pvnum=0

FULLREV=""
if [ ${OS} = "09" ]
then
FULLREV=`awk '/^fv:/ {print $2}' /system/UX-CORE/index`
else
FULLREV=`uname -r`
fi

FSTAB=/etc/mnttab

echo "VGINFO of `uname -nm` $FULLREV \$Rev: 2.04 \$"
date

lvlnboot -v 2>/dev/null | grep "^Dump:" | awk '{print $2,$4}' > /tmp/dump$$

vgdisplay | grep -v "Volume groups" > /tmp/vgdisplay$$

awk '\
        {if ( NF == 0) {
		printf "\n" 
	}
        else {
		printf "%s ", $NF}
        }' < /tmp/vgdisplay$$ > /tmp/vglist$$

swapinfo -d |  awk '{print $NF}' > /tmp/swap$$

> /tmp/pv$$
vgdisplay -v | grep "^   PV Name" |
	       grep -v "Alternate Link" | 
	       awk '{print $3}' |
               while read a
	       do
		 grep -q "$a" /tmp/pv$$ || echo "$a" >> /tmp/pv$$
	       done
#
echo PVs=`cat /tmp/pv$$ | wc -l ` VGs=`cat /tmp/vglist$$ | wc -l`

cat /tmp/vglist$$;rm -f /tmp/vglist$$

for pv in `cat /tmp/pv$$`
do
	echo "#####PV#${pvnum}"
	pvnum=pvnum+1

	pvdisplay  $pv > /tmp/curpv$$
	grep -Ev "Physical|Alternate|alternate" /tmp/curpv$$ | awk '{printf "%s ", $NF}'
	if [ ${OS} = "09" ]
	then
           echo "N/A \c" 
	fi
	RPV=`echo $pv | sed s/dsk/rdsk/`
	DISKTYPE=`diskinfo $RPV |grep "product id" | awk '{print $3}'`
	HWPATH=`lssf $pv |  awk '{print $(NF -1)}'`
	echo "$DISKTYPE $HWPATH\c"

	integer i=1
	awk '/Alternate Link/ {print $3}' /tmp/curpv$$ | while read PVLINK[i]
	do
	    HWPATH[i]=`lssf ${PVLINK[i]} |  awk '{print $(NF -1)}'`
	    let i=i+1
	done

	if [ $i -eq 1 ]
	then
	    echo " NOPVLINK NOPVLINK"
	else
	    integer j=1

	    while [ $j -ne $i ]
	    do
		printf " %s %s " ${PVLINK[j]} ${HWPATH[j]}
	        let j=j+1
	    done
	    echo 
	fi

        pvdisplay -v $pv | awk '\
		BEGIN{num=0;str=""}
		{
		  if ( $0 ~ /PE   Status   LV/){
			for(;;){
				getline
				if ( $0 == "" ){
					pr();
					break;
				}
				if ( $2 == "free" ) {
					if ( $2 == str ){
						num++;
					}else{
						pr();
						str=$2;
						num=1;
					}
				}else{
					if ( $3 == str ){
						num++;
					}else{
						pr();
						str=$3;
						num=1;
					}
				}
			}
		  }else{
			continue
		  }
		}

		function pr()
		{
		if ( num > 0 ){
			printf("%s %d\n",str,num);
			str="";
			num=0;
		}
		}'| while read LVNAME LVSIZE
			do
			echo "$LVNAME $LVSIZE \c"
			F1=`dirname $LVNAME`
			F2=`basename $LVNAME`
			RLV=`printf "%s/r%s" $F1 $F2`
			if [ "$LVNAME" != "free" ]
			then
			lvdisplay $LVNAME | egrep -v "\-\-\- |/dev/" | awk '{printf "%s ", $NF}'
				
			else
				echo "-1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 \c"
			fi
			FST=`grep "$LVNAME " $FSTAB | awk '{print $3}'`
			case ${FST} in
			hfs)
			tunefs -v $RLV >/dev/null 2>&1
			if [ $? = 0 ]
			then
				tunefs -v $RLV | awk '\
						/super/    {if ($6 != "") \
						{printf "%s ",$6} else { printf "/??? "}} \
						/minfree/  {printf "%s ",$2}  \
						/^bsize/   {printf "%s ",$2}  \
						/fsize/    {printf "%s ",$2}  \
						/rotdelay/ {printf "%s ",$4}  \
						/nbfree/   {printf "%s ",$2}  \
						/nifree/   {printf "%s", $6} '
			else
				echo "/??? -1 -1 -1% -1ms -1 -1\c"
			fi
			;;
			vxfs)
			   MNTPT=""
                           grep "$LVNAME " $FSTAB | read dummy MNTPT dummy
                           if [ -z "${MNTPT}" ]
                             then
                                   echo "/??? -1 -1 -1% -1ms -1 -1\c"
                             else
                           MINFREE="";BLOCKSIZE="";FRAGSIZE="";FREEBLOCKS="";FREEINODES=""
                           df -t ${LVNAME} | grep "percent minfree" | read  MINFREE dummy
			   df -g ${LVNAME} > /tmp/df$$
                           grep "file system block" /tmp/df$$ | read BLOCKSIZE nul nul nul nul FRAGSIZE nul
                           grep "total blocks" /tmp/df$$ | read nul nul nul FREEBLOCKS nul
                           grep "total i-nodes" /tmp/df$$ | read nul nul nul nul FREEINODES nul
                           echo "${MNTPT} ${BLOCKSIZE} ${FRAGSIZE} ${MINFREE} -1ms ${FREEBLOCKS} ${FREEINODES}\c"
                           fi
                           ;;

			*)
			  echo "/??? -1 -1 -1% -1ms -1 -1\c"
				;;
                esac
			IsFs="y"

			if [ `grep  -c "${LVNAME}$" /tmp/swap$$` -gt 0 ]
			then 
				echo " swap\c"
				IsFs=""
			fi

			if [ `grep  -c "$F2" /tmp/dump$$`  -gt 0 -a `grep -c "$pv" /tmp/dump$$` -gt 0 ]
		        then
			     echo "/dump\c"
			     IsFs=""
		        fi 

			if [ "$IsFs" = "y" ]
			then
				echo " fs\c"
			fi
			FST=`grep "$LVNAME " $FSTAB | awk '{print $3}'`
			if [ X${FST} = "X" ]
			then
				echo " nofs\c"
			else
				echo " ${FST}\c"
			fi
			echo
		  done

done

echo "[End VGINFO]"
if [ ${OS} != "09" ]
then
	echo "[Start Interfaces]"
	ioscan -FC ext_bus | cut -d':' -f 11
	echo "[End Interfaces]"
fi

rm -f /tmp/pv$$ /tmp/swap$$ /tmp/dump$$ /tmp/vgdisplay$$ /tmp/curpv$$ /tmp/df$$

echo
print "*******************************************************************************"  
print "*******                   END OF VGCOLLECT for XVG                      *******"
print "*******************************************************************************"
}

redirect()
{

#
# Redirect stdout to file
#

OUTPUT_FILE=${SAVE_DIR}/${SCRIPT_NAME}.$(date +%m%d)
print Output will be save in ${SAVE_DIR}/${SCRIPT_NAME}.$(date +%m%d)
exec > $OUTPUT_FILE 2>&1

# Attach mail header if to be e-mailed
attach_header

# Redirect stderr 

ERR_FILE="/dev/null"
exec 2>>$ERR_FILE
}


check_user()
{ 

#
#  Make sure 'root' is executing the script
#


if [ $(id -u) -ne 0 ]

then
	print
	print "Sorry! You must be root to run the $SCRIPT_NAME script"
	print
	exit 1
fi
}

summary_info()
{

print "*******************************************************************************"  
print "*******                                                                 *******"
print "*******                    SUMMARY  INFORMATION                         *******"
print "*******                                                                 *******"
print "*******************************************************************************"
DATE=$(date)
print "$DATE                                       $SCRIPT_NAME $VER"
print
print

 #
 #  Identify customer
 #
 
    print "Company Name     : $CUST_NAME"

 #
 #  Identify System 
 #

    print "System ID        : $SYS_ID"
    print

    
 #
 #  Call 'hostname' to get system hostname
 #

    print "Host Name        : $(hostname)"

 #
 #  Get domain name
 #

    print "Domain Name      : $DNS_DOMAIN"

 #
 #  Get system type
 #

    MODEL=$(uname -m)
    print "System Type      : $MODEL"

 
 #
 #  Get OS Version
 #

    if [ $OS_VERSION -lt 10 ]
    then
        REV_LEVEL="HP-UX $(grep fv /system/UX-CORE/index | awk '{print $2}')"
        print "Operating System : $REV_LEVEL"
    else
        REV_LEVEL="$(uname -a | awk '{print $1 " " $3 " rev. " $4}')"
    print "Operating System : $REV_LEVEL"
    fi

 #
 #  Get SPU ID
 #

    print "SPU ID           : $SPU_ID"
    
 #
 #  Get user license
 #

    print "User License     : $USER_LICENSE"

 #
 #  Get IP and MAC Address from installed lan cards
 #  

    for LAN in $(lanscan | grep lan | awk '{print $5}')
    do
       IP_ADDRESS=$(ifconfig $LAN | grep inet | awk '{print $2}')
       MAC_ADDRESS=$(lanscan | grep $LAN | awk '{print $2}') 
       print "IP  addr ($LAN)  : $IP_ADDRESS"
       print "MAC addr ($LAN)  : $MAC_ADDRESS"
    done 

 #
 #  Get Installed Memory
 #
 
 #
 # Determine the memory size.
 #
 
 # Real memory expressed in units of pages (4 kbytes per page).
    
OS_VERSION=$(uname -r | awk -F. '{print $2}')
if [ $OS_VERSION -lt 10 ]
then
    REAL_MEM=`print 'physmem/D'| adb /hp-ux /dev/kmem | tail -1 | \
              awk '{print $2}'`
else
    REAL_MEM=`print 'physmem/D'| adb /stand/vmunix /dev/kmem | tail -1 | \
              awk '{print $2}'`
fi

   print "Real Memory      : `expr ${REAL_MEM} / 256` Mbytes"
 

#
#  Get swap memory
#

  swapinfo -m | grep dev | awk '{print "Swap Space       : "$2" Mbytes on "$9}'

#
# Call 'who -b' to see when the system was last rebooted.
#

   print "Last Reboot      : "$(who -b | sed 's/^.*boot  //')

#
# Call 'who -r' to see what run level the machine is at.
#

   print "Run Level        : "$(who -r | sed 's/^.*run-level //' | \
                                sed 's/ .*$//')

#
# Call 'uptime' to look at load averages
#

   AVERAGE=$(uptime | sed 's/^.*average: / /')
   print "Load Averages    :$AVERAGE"

}


mail_header()
{
#
#  This function adds a mail header for e-mail via Internet
#
print "From: $CUST_NAME                      " 
print "Subject: Output of $SCRIPT_NAME script"
print "Priority: Urgent"
print ""
}

print_footer()
{

#
#  This function prints the closing footer
#
print "*******************************************************************************"  
print "*******                     END OF SNAPSHOT SCRIPT                      *******"
print "*******************************************************************************"
echo
echo
}

capture()
{

#############################################################################
#
#                              VARIABLES
#
#############################################################################


SYSTEM_TYPE=$(uname -m | awk -F/ '{print $2}' | cut -c 1)00

SUB_SYSTEMS="HARDWARE OS SYSTEM NETWORKING"
ALL_SUB_SYSTEMS="HARDWARE OS SYSTEM NETWORKING INETSVC LMU LMX NETWARE NFS_NIS OTS_FTAM SLIP SNAP TIO_DTC X25"

NIS_SERVER="YES"
NIS_CLIENT="YES"

SCRIPT_CAPS=$(print $SCRIPT_NAME | tr "[a-z]" "[A-Z]")

#
# Locate the temporary holding directory under /tmp
#
	TMP_DIR=>/dev/null

OUTPUT_SHAR_FILE=/tmp/capture.$(date +%m%d%H%M)
ANALYZE_FILE=$TMP_DIR/analyze.output
AUDIT_LOGS=$TMP_DIR/audit.logs
CRON_INFO=$TMP_DIR/cron_info.$$
CRON_JOBS=$TMP_DIR/cron_jobs.$$
GATED_FILES=$TMP_DIR/gated_files.$$
DIAG_LOGS=$TMP_DIR/diag_logs.$$
NAMED_FILES=$TMP_DIR/named_files.$$
NFS_FILES=$TMP_DIR/nfs_files.$$
NIS_MAPS=$TMP_DIR/client.nismaps
MAIL_FILES=$TMP_DIR/mailfiles.$$
RBOOTD_FILES=$TMP_DIR/rbootd_files.$$
RC_FILES=$TMP_DIR/rc_files.$$
SLIP_FILES=$TMP_DIR/slipfiles.$$
SNAP_FILES=$TMP_DIR/snapfiles.$$
SYS_FILES=$TMP_DIR/sys_files.$$
SAR_FILE=$TMP_DIR/sar_file.$$
TMPFILE1=$TMP_DIR/tmpfile1.$$
TMPFILE2=$TMP_DIR/tmpfile2.$$

SHAR_ARGS="-bCZshm"
SAR_OPTS="b d y c w a q v m"


#############################################################################
#
#                              FUNCTIONS
#
#############################################################################


function SYSTEM_Info {

bigtitle "General System Information"

#
# Call 'who -rRub' to see when the system was last booted, the current
# system run-level, and the list of currently logged-in users with their
# respective hostnames.
#
execute who -rRub


#
# Print inittab file
#
cat_file /etc/inittab


#
# Call 'dmesg' to see console message buffer.
#
title "System Diagnostic Messages"
execute dmesg


#
# If we are on an 800 system, call 'sar' to gather system data
#
if [ $SYSTEM_TYPE -eq 800 ]
then
	title "System Activity Reporter Information"

	execute sar "-o $SAR_FILE 5 20" \ "Output from $(whence sar) 5 20"

	for OPT in $SAR_OPTS
	do
		execute sar "-f $SAR_FILE -M$OPT" \
		"Output from $(whence sar) -$OPT"
	done
fi


#
# Look for - but do not execute - well known performance monitors
#
title "Performance Monitors Available"

PERFORMANCE_TOOLS="/usr/bin/top /usr/contrib/bin/monitor /usr/perf/bin/glance \
/usr/perf/bin/gpm /usr/perf/bin/scope.start /usr/perf/bin/rx \
/opt/perf/bin/glance /opt/perf/bin/gpm /opt/perf/bin/scope.start /opt/perf/bin/rx"

for TOOL in $PERFORMANCE_TOOLS
do
         if [ -f $TOOL ]
         then
	 echo "$(echo $TOOL) is available"
         print
         fi
done


#
# Collect the following files: cron.allow, at.allow.
# Also get the contents of the crontabs and atjobs directories.
#
title "CRON Information"
if [ $OS_VERSION -lt 10 ]
then 
	cat_file  /usr/lib/cron/at.allow
	cat_file  /usr/lib/cron/at.deny
	cat_file  /usr/lib/cron/cron.allow
	cat_file  /usr/lib/cron/cron.deny
	cat_file  /usr/spool/cron/.ataids
	cat_file  /usr/spool/cron/.cronaids
else
	cat_file  /var/adm/cron/at.allow
	cat_file  /var/adm/cron/at.deny
	cat_file  /var/adm/cron/cron.allow
	cat_file  /var/adm/cron/cron.deny
	cat_file  /var/spool/cron/.ataids
	cat_file  /var/spool/cron/.cronaids
fi


#
# Collect the scripts launched in the various cron schedules.
# Call 'sed' and 'awk' to parse out the filenames listed in the
# crontab files.  Call 'file' to make sure they are ascii text
# files and not binaries.
#
cat /dev/null > $TMPFILE1
cat /dev/null > $TMPFILE2

if [ $OS_VERSION -lt 10 ]
then
	ATJOB_DIR=/usr/spool/cron/atjobs
	CRONTAB_DIR=/usr/spool/cron/crontabs
	CRON_DIR=/usr/lib/cron
else
	ATJOB_DIR=/var/spool/cron/atjobs
	CRONTAB_DIR=/var/spool/cron/crontabs
	CRON_DIR=/var/adm/cron
fi

if [ -f $CRONTAB_DIR/* ]
then
	for CRONTAB in $(cat $CRON_DIR/cron.allow)
	do
		if [ -s $CRONTAB_DIR/$CRONTAB ]
		then
			cat_file $CRONTAB_DIR/$CRONTAB
			cat_file $CRONTAB_DIR/$CRONTAB NO >> $TMPFILE1
		fi
	done
fi

if [ -f $ATJOB_DIR/* ]
then
	for ATJOB in $(file $ATJOB_DIR/* | egrep "text\$" | \
		       awk -F: '{print $1}')
	do
		if [ -s $ATJOB ]
		then
			cat_file $ATJOB
		fi
	done
fi

if [ -s $TMPFILE1 ]
then
	title "CRON Job Collection"
	cat $TMPFILE1 | sed -e '/\#/d' -e '/^$/d' | awk '{print $6}' | \
			sort | uniq | while read JOB
	do
		file $JOB >> $TMPFILE2
	done

fi


#
# Call 'audsys' to determine if system auditing is enabled.  If it is,
# call 'audevent' to see what events are being logged.  Then, for each
# audit logfile displayed by 'audsys' add the logfile to the system
# logfile shar list.
#
title "Audit Sub-system Collection"
audsys > /dev/null 2>&1
if [ $? -eq 0 ]
then
	execute audsys
	execute audevent

else
	print
	print
	print "The Audit Sub-system is not enabled on this system."
	print
	print
fi


#
# If the /etc/switch directory and the swithover startup script exists
# then collect SwitchOver information.
#
title "SwitchOver/UX Configuration"
if [ $OS_VERSION -lt 10 ]
then
	SWITCHRC=/etc/switch/switchrc
else
	SWITCHRC=/etc/rc.config.d/switchover
fi

if [ -d /etc/switch ] && [ -f $SWITCHRC ]
then
	SWITCH_INFO=$(grep ^SWITCH_INFO= $SWITCHRC | awk -F= '{print $2}' | \
		      sed 's/ .*$//')

	if [ -f $SWITCH_INFO ]
	then
		display_daemon switch
		cat_file $SWITCH_INFO

		LOGFILE=$(grep logfile $SWITCH_INFO | awk -F= '{print $2}')
		if [ -f $LOGFILE ]
		then
			cat_file $LOGFILE
		fi
	else
		print
		print
		print "SwitchOver/UX appears to be installed but the \"$SWITCH_INFO\""
		print "file does not exist on this system."
		print
		print
	fi
else
	print
	print
	print "SwitchOver/UX is not configured on this system."
	print
	print
fi



#
# List sensitive system files such as password and group
# files.  Some customers object to mailing this info over
# the internet, hence the variable to allow these files
# to be ignored.
#

if [ $SENSITIVE_FILES = YES ]
then
    title "Sensitive System Files"

    title "/etc/passwd file"
      cat_file /etc/passwd

    title "/etc/group file"
      cat_file /etc/group

    title "System Security Bypass Files"
      cat_file /.rhosts
      cat_file /etc/hosts.equiv

if [ $OS_VERSION -lt 10 ]
then
    title "/usr/adm/inetd.sec file"
      cat_file /usr/adm/inetd.sec
else
    title "/var/adm/inetd.sec file"
      cat_file /var/adm/inetd.sec
fi

    title "/etc/inetd.conf file"
      cat_file /etc/inetd.conf

    title "/etc/securetty file"
      cat_file /etc/securetty

    title "/etc/services file"
      cat_file /etc/services
fi

#
# Check the /etc/shutdown.d directory for any shutdown scripts
#
if [ $OS_VERSION -lt 10 ] && [ -f /etc/shutdown.d/* ]
then
	title "System Shutdown Scripts"
	for FILE in $(ls -1 /etc/shutdown.d/*)
	do
		cat_file $FILE
	done
fi

}


function OS_Info {

bigtitle "HP-UX Operating System Information"

#
# Call 'what' on kernel to see which subsystems and patches are installed.
# The OS version determines the name of the kernel.  If we are on an s800
# call 'sysdef' to analyze the kernel.  Call 'get_kgenfile', 'get_kdfile'
# or 'get_sysfile' to print out live kernel configuration parameters.
#
title "Kernel Configuration Information"
if [ $OS_VERSION -lt 10 ]
then
	KERNEL=/hp-ux
else
	KERNEL=/stand/vmunix
fi

execute what $KERNEL
execute what /lib/libc.a
execute what /lib/libc.sl

if [ $OS_VERSION -lt 10 ]
then
	if [ $SYSTEM_TYPE -eq 800 ]
	then
		execute what /etc/conf/lib/libhp-ux.a
	else
		execute what /etc/conf/libhp-ux.a
	fi
else
	execute what /usr/conf/lib/libhp-ux.a
fi

if [ $OS_VERSION -lt 10 ]
then
	if [ $SYSTEM_TYPE -eq 800 ]
	then
		title "Kernel Active S800 Information"
		execute get_kgenfile $KERNEL
		cat_file /etc/conf/S800/config.h
		cat_file /etc/conf/gen/S800

		title "System Definition Analysis"
		execute sysdef
	else
		title "Kernel Active dfile Information"
		execute get_kdfile $KERNEL
		cat_file /etc/conf/dfile
	fi
else
	title "Kernel Active Sysfile Information"
	execute get_sysfile $KERNEL
	cat_file /stand/system

	title "System Definition Analysis"
	execute sysdef
fi


#
# Determine if CA-UNICENTER is installed on this system.  We check
# for the string "enf" in the kernel what output.  If this string
# is found we assume CA-UNICENTER is installed in the kernel.
#
title "CA-UNICENTER"
if [[ ! -z $(what $KERNEL | grep -i enf) ]]
then
	print "CA-UNICENTER is installed in this kernel"
else
	print "CA-UNICENTER is NOT installed in this kernel"
fi


#
# Call 'adb' looking for some of the more common kernel parameters
# that might not have been displayed by the above commands.  The
# parameters include: shmmni, maxfiles, maxfiles_lim, maxuprc,
# nproc, nfile, ninode, npty, nbuf and bufpages.
#
title "Common Kernel Parameters"
if [ $OS_VERSION -lt 10 ]
then
	execute adb "" "Output from $(whence adb) $KERNEL /dev/kmem:" \
		adb $KERNEL /dev/kmem <<-EOF
		shmmni/D
		maxfiles/D
		maxfiles_lim/D
		maxuprc/D
		nproc/D
		nfile/D
		nflocks/D
		ninode/D
		npty/D
		nbuf/D
		bufpages/D
		EOF
else
	execute adb "" "Output from $(whence adb) $KERNEL /dev/kmem:" \
		adb $KERNEL /dev/kmem <<-EOF
		shmmni/D
		maxfiles/D
		maxfiles_lim/D
		maxuprc/D
		nproc/D
		nfile/D
		nflocks/D
		ninode/D
		npty/D
		nbuf/D
		bufpages/D
		fsend_cksum/D
		EOF
fi


#
# Print listings of system and filesets directories to list
# product and patch entries
#
title "Installed Software Products & Patch Information"
if [ $OS_VERSION -lt 10 ]
then

 cd /system
   print 
   print "FileSet Name    FileSet Description                    Revision"
   echo "--------------  -----------------------------------    ----------"

   for fileset in `ls -d *`; do
      if [ -d $fileset ]; then
         if [ -f $fileset/index ]; then
            fd=`grep fd: $fileset/index | cut -d: -f2`
            fv=`grep fv: $fileset/index | cut -d: -f2`
            fn=`grep begin: $fileset/index | cut -d: -f2`
            if [ "Z$fn" = "Z" ]; then
               fn=$fileset
            fi
            printf %-14.14s%-40.40s%-20.20s\\n $fn "$fd" $fv
         else
            printf %-16.16s%-40.40s\\n $fileset "Missing index"
         fi
      fi
   done


#
# Print listings of /system and /etc/filesets to get any product entries
# that were not picked up by above awk script.
#
title "Installed Patch Information"

print
title "Patch listings in /system:"
print

print "Command Patches:"
ll /system |grep " PHCO"
print

print "Kernel Patches:"
ll /system |grep " PHKL"
print

print "Network Patches:"
ll /system |grep " PHNE"
print

print "Subsystem Patches:"
ll /system |grep " PHSS"
print

title "Patch listings in /etc/filesets:"

print "Command Patches:"
ll /etc/filesets |grep " PHCO"
print

print "Kernel Patches:"
ll /etc/filesets |grep " PHKL"
print

print "Network Patches:"
ll /etc/filesets |grep " PHNE"
print

print "Subsystem Patches:"
ll /etc/filesets |grep " PHSS"
print

else

execute swlist "-l product"

fi


#
# Use 'adb' to see what the pga_control kernel variable is set to.
#
if [ $OS_VERSION -lt 10 ] && [ $SYSTEM_TYPE -eq 800 ]
then
	title "Process Deactivation Check"
	execute adb "" \
	"Output from print \"pga_control?D\" | $(whence adb) /hp-ux:" \
	adb /hp-ux <<-EOF
	pga_control?D
	EOF
fi


#
# Call 'ps -efl' to find running processes.
#
title "Process Status Information"

if [ $OS_VERSION -lt 10 ]
then
    ps -ef
else

# A script to print "ps" information in indented tree form.
# Author: Eldon Brown
#
# (c)Copyright 1989,1990,1991, by Eldon R. Brown. 
# All Rights Reserved.  This copyright and the above "SRCID" strings
# must not be removed.  Permission is granted for unrestricted
# non-commercial use on all non-source code licensed systems.
#
# Provided by HP Bellevue Quick Start


# Initialize Constants:
	progname=`basename $0`

# Define Macros:

# Initialize Variables:
	TMP=/tmp/ps-ind$$

# Main:

	pid=0
	while [ "$1" ]
	do
		case "$1" in
		-*) pid=$1; shift;;
		*)  node=$1; shift;;
		esac
	done

	if [ "$node" ]
	then
		remsh $node ps -efl >$TMP &&
		remsh $node /bin/sh -c "uname\ -a; uptime" || exit 2
	else
		ps -efl >$TMP 
		uname -a
		uptime

	fi 
	echo 

	sort +4n +3n < $TMP | 
	awk '
	{
	    pid = $4;
	    state[pid] = $2;
	    ppid = $5;
	    usr[pid] = $3;
	    cmd[pid] = substr($0,83,40);

	    child_count[ppid]++;
	    tree[ppid","child_count[ppid]] = pid;
	}
	END {
	    ppid = '$pid'+ 0;		# get cmd line arg
	    if (ppid < 0) ppid = -ppid;	# make it positive
	    j = 0;

	    while ( j >= 0 ) {
		while ( ++child_index[ppid] <= child_count[ppid]) {
	            stack[j++] = ppid;
		    pid = tree[ppid","child_index[ppid]];
		    USR = usr[pid];
		    CMD = cmd[pid];
		    STATE = state[pid];
		    if ( STATE == "S" ) STATE = "";
		    if ( USR == prev_usr ) USR = "";
		    printf("%-2s%-8s%*.0s %5.5d %s\n",STATE,USR,(j-1)*6, "", pid, CMD);
		    prev_usr = usr[pid];
		    ppid = pid;
		    if (child_index[pid] > child_count[pid] ) {
		        ppid = stack[--j];
		    }
		}
		ppid = stack[--j];
	    }
	} '

	rm -f $TMP
# end script
fi


#
# Call 'ipcs' to list Inter Process Communication info
#
title "Inter-Process Communication"
execute ipcs -a


#
# Call 'lsof' to list Open Files info
#
COMMAND=lsof
if [[ ! -z $(whence $COMMAND) ]]
then
	title "Open Networking Files/Ports Information"
	execute $COMMAND -n
fi
}


function HARDWARE_Info {

bigtitle "Hardware Information"

#
# If we are on an 800 system, check if 'DUI' is available.  Use it to
# generate a system map if available.  If we are on a 700 system, use
# 'cstm' to generate an iomap.
#
title "I/O Device Information"
if [ $SYSTEM_TYPE -eq 800 ]
then
	execute DUI "" "System Map generated by DUI:" \
	DUI <<-EOF
	sysmap
	mapall
	exit
	exit
	EOF
else
	execute cstm "" "I/O Map generated by CSTM:" \
	cstm <<-EOF
	map
	exit
	EOF
fi

#
# If we are on any 800 system, call 'ioscan' with the -kf option to
# generate an iomap using the kernels IO structures.  If we are on a
# 700 system, and we are running 10.0 or better, use the -kf option.
# If we are on 9.X, the -k option is not available so only use -f.
#
if [ $SYSTEM_TYPE -eq 800 ]
then
	execute ioscan -kf
else
	if [ $OS_VERSION -gt 8 ]
	then
		if [ $OS_VERSION -gt 9 ]
		then
			execute ioscan -kf
		else
			execute ioscan -f
		fi
	fi
fi

#
# Determine disk firmware
#
title "Disk Firmware Information"
disk_firmware

#
# Print checklist or fstab file
#
title "Disk Information"
if [ $OS_VERSION -lt 10 ]
then
	cat_file /etc/checklist
else
	cat_file /etc/fstab
fi

#
# Print mnttab file
#
cat_file /etc/mnttab

#
# Call 'bdf' to get listing of mounted filesystems
#
execute bdf -i


#
# Call 'tunefs' to collect Tuneable File System parameters
#
title "Tunable File System Information"
for DISK in $(bdf -t hfs | grep \/dev\/ | awk '{print $1}' | sort)
do
	execute tunefs "-v $DISK"
done


#
# Call 'swapinfo' to collect Swap Space information
#
title "Swap Space Information"
if [ $OS_VERSION -lt 10 ]
then
	execute swapinfo -adfhw
else
	execute swapinfo -adfw
fi


#
# Call 'lpstat' to collect printer and spooler information.  Call
# 'npstat' also to see if OpenSpool is being used.
#
title "Printer Information"
execute lpstat "-t -i"
execute npstat "-H $(hostname)"
}


function NETWORKING_Info {

bigtitle "General Networking Information"

if [ $OS_VERSION -lt 10 ]
then
	FILESETS="LAN NET NETINET"
	verify_fileset Networking $FILESETS

	if [ $? -ne 0 ]
	then
		print
		print "One or more \"NETWORKING\" filesets are missing"
		print "Some \"NETWORKING\" data may not be collected"
		print
	fi

	what_fileset $FILESETS
else
	PRODUCTS="LAN-RUN NET-RUN"
	what_products Networking $PRODUCTS

	if [ $? -ne 0 ]
	then
		print
		print "One or more \"NETWORKING\" filesets are missing"
		print "Some \"NETWORKING\" data may not be collected"
		print
	fi
fi


#
# Call 'nettl' to print the current logging/tracing configuration
#
title "Network Logging Information"
execute nettl -ss

if [ $OS_VERSION -gt 9 ]
then
	execute nettlconf -s
fi


#
# If we are running on an OS prior to 10.00 all we can do is
# print the clusterconf file.  10.00 or later we can use the
# 'dcnodes' command to dump the cluster map.
#
if [ $OS_VERSION -lt 10 ]
then
	if [ -f /etc/clusterconf ]
	then
		title "Diskless Cluster Configuration"
		cat_file /etc/clusterconf
	fi
else
	title "Diskless Cluster Configuration"
	execute dcnodes -SLh
fi


#
# Call 'lanscan' to print lancard states
#
title "Ethernet / Token Ring / 100VG Card Information"
if [ $OS_VERSION -lt 10 ]
then
	execute lanscan
else
	execute lanscan -v
fi

#
# Call 'netstat -in' to get a listing of running interfaces.  Pass
# the list to 'ifconfig' to print their IP address, state, etc.
# Also call lanconfig for each valid interface to get their
# encapsulation configuration.
#
for CARD in $(netstat -in | grep lan | awk '{print $1}' | sed 's/\*//')
do
	execute ifconfig "$CARD" > /dev/null 2>&1
	if [ $? -eq 0 ]
	then
		execute ifconfig "$CARD"
		execute lanconfig "$CARD"
	fi
done

#
# Call 'linkloop' to verify connectivity with link-level loopback
#
if [ $OS_VERSION -lt 10 ]
then
	lanscan | grep 0x | while read INTERFACE
	do
		MACADDR=$(print $INTERFACE | awk '{print $2}')
		DEVFILE=/dev/$(print $INTERFACE | awk '{print $5}')
		execute linkloop "-v -f $DEVFILE $MACADDR"
	done
else
	lanscan | grep 0x | while read INTERFACE
	do
		MACADDR=$(print $INTERFACE | awk '{print $2}')
		NMID=$(print $INTERFACE | awk '{print $7}')
		execute linkloop "-v -i $NMID $MACADDR"
	done
fi

#
# On some systems the /dev/lan? file doesn't match the lu number or
# the NameUnit listed by 'lanscan'.  So on a pre-10.0 box, we should call
# lanscan with all of the /dev/lan? files to make sure we get all of the
# available ones.  This might cause some additional garbage in the output
# file, but better that than not getting the stats of a valid interface.
#
# On 10.X systems, 'lanadmin' needs the NMID rather than the /dev/lan file
# so use 'lanscan' and grep for the NMID.  Again, to be safe we will
# check each NMID reported by 'lanscan' in case the customer's system is
# configured differently than we expect.
#
if [ $OS_VERSION -lt 10 ]
then
	COMMAND1=landiag
else
	COMMAND1=lanadmin
fi

if [[ ! -z $(whence $COMMAND1) ]]
then
	COMMAND2=lanscan
	if [[ ! -z $(whence $COMMAND2) ]]
	then
		if [ $OS_VERSION -lt 10 ]
		then
			for CARD in $(ls -1 /dev/lan*)
			do
				execute $COMMAND1 -t <<-EOF
				lan
				name $CARD
				display
				quit
				EOF
			done
		else
			for NMID in $($COMMAND2 | grep 0x | awk '{print $7}')
			do
				execute $COMMAND1 -t <<-EOF
				lan
				nmid $NMID
				display
				quit
				EOF
			done
		fi
	else
		print
		print
		print "The command \"$COMMAND2\" is not executable"
		print "No data from \"$COMMAND1\" will be collected"
		print
		print
	fi
else
	print
	print
	print "The command \"$COMMAND1\" is not executable"
	print
	print
fi


#
# For each lan device file, call 'fddistat' to see if it is a valid
# fddi device file.  If this call completes successfully, call
# 'fddistat' and 'fddinet' for the interface and collect the output.
#
title "Installed FDDI Card Information"
FDDI_CARDS=0
for CARD in $(netstat -in | grep lan | awk '{print $1}' | sed 's/\*//')
do
	execute fddistat /dev/$CARD NO > /dev/null 2>&1
	if [ $? -eq 0 ]
	then
		let FDDI_CARDS=$FDDI_CARDS+1

		execute fddistat /dev/$CARD
		execute fddistat "-n /dev/$CARD"
		execute fddinet /dev/$CARD
		execute fddinet "-n /dev/$CARD"
	fi
done

if [ $FDDI_CARDS = 0 ]
then
	print
	print
	print "There are no Active FDDI cards installed in this system"
	print
	print
fi


#
# Call 'netstat' with various parameters to collect information about
# interfaces, open connections, etc.  At 10.01 netstat supports the
# -v option in conjuction with -r.  Test to see if using the -v flag
# works.  If it does, use it - if not, don't.  Also, 10.0 added the
# -g flag but stopped supporting the -R flag, so check which version
# OS we're running and act accordingly.
#
title "Netstat Information"
execute netstat -in
execute netstat -m
execute netstat -rs
execute netstat -s
execute netstat -an

execute netstat -rnv > /dev/null 2>&1
if [ $? -eq 0 ]
then
	execute netstat -rnv
else
	execute netstat -rn
fi

if [ $OS_VERSION -lt 10 ]
then
	execute netstat -R
else
	execute netstat -g
fi


#
# If we are running an OS of 10.X or better call 'nettune' to display
# values of tunable network parameters.  If we are running an OS prior
# to 10.X call the built-in function 'NETTUNE_Info' to do the same thing.
#
title "Networking Kernel Parameters"

if [ $OS_VERSION -lt 10 ]
then
	NETTUNE_Info
else
	execute nettune -lw
fi


#
# Call 'strvf' to print Streams configuration
#
title "Streams Verification"
execute strvf -v


#
# Call 'arp' to print the contents of the arp cache.  Depending on the
# OS version running, pass different parameters.
#
title "Arp Cache Information"
if [ $OS_VERSION -lt 9 ]
then
	execute arp -a
else
	execute arp -A
fi


#
# Collect /etc/hosts file
#
title "Hosts Name Database Collection"
cat_file  /etc/hosts


#
# If the proxy server is enabled call 'proxy' to print the contents
# of the proxy cache.
#
if [ $OS_VERSION -lt 10 ]
then
	title "Proxy Cache Information"
	execute proxy list > /dev/null 2>&1
	if [ $? -eq 0 ]
	then
		execute proxy list
	else
		print
		print
		print "The Proxy Cache is not enabled on this system"
		print
		print
	fi
fi


#
# Print inetd.conf and inetd.sec files
#
title "Inetd Information"
cat_file /etc/inetd.conf

if [ $OS_VERSION -lt 10 ]
then
	cat_file /usr/adm/inetd.sec
else
	cat_file /var/adm/inetd.sec
fi


#
# Print services file
#
title "Services Information"
cat_file /etc/services
}


function ANALYZE_Info {

bigtitle "Collecting System ANALYZE Information"

if [ $OS_VERSION -lt 10 ]
then
	KERNEL=/hp-ux
else
	KERNEL=/stand/vmunix
fi

COMMAND=analyze
if [[ ! -z $(whence $COMMAND) ]]
then
	execute $COMMAND "-PALUM /dev/mem $KERNEL" > $ANALYZE_FILE
	print
	print
	print "Output from $(whence $COMMAND) was saved in file: analyze.output"
	print
	print
	print
else
	print
	print
	print "The command \"$COMMAND\" is not executable"
	print
	print
fi
}


function INETSVC_Info {

bigtitle "Internet Services Information"

if [ $OS_VERSION -lt 10 ]
then
	FILESETS="ARPA-RUN"
	verify_fileset InternetSrvcs $FILESETS

	if [ $? -ne 0 ]
	then
		return
	fi

	what_fileset $FILESETS
else
	PRODUCTS="INETSVCS-BOOT INETSVCS-INETD INETSVCS-RUN"
	what_products InternetSrvcs $PRODUCTS
	
	if [ $? -ne 0 ]
	then
		return
	fi
fi


#
# Print ntp.conf file
#
if [ $OS_VERSION -gt 9 ]
then
	title "NTP (Network Time Protocol) Configuration"
	display_daemon xntpd

	if [ $? -gt 0 ]
	then
		execute ntpq -pn
	fi

	cat_file /etc/ntp.conf
fi


#
# Print nsswitch.conf file
#
title "NSSwitch Configuration Information"
cat_file /etc/nsswitch.conf


#
# Collect information about bootp
#
title "Bootp Configuration Information"
display_daemon bootpd
cat_file /etc/bootptab


#
# Collect information about rbootd
#
title "Rbootd Configuration Information"
display_daemon rbootd
cat_file /etc/boottab


#
# Since we will be sending kill signals, we want to make sure we are
# sending them to a valid gated process.  The gated.pid file
# contains the PID number of the currently running (or last run)
# gated process.  Use 'ps' to check for a running gated process and
# make sure the process number matches the contents of the gated.pid
# file before sending kills.
#
# Until we are sure gated is running we assume it is not.
#
title "Gated Configuration Information"
GATED_RUNNING=NO

if [ $OS_VERSION -lt 10 ]
then
	GATED_PIDFILE=/etc/gated.pid
	GATED_VERSFILE=/etc/gated.version
	GATED_DATA_DIR=/usr/tmp
	GATED_DAEMON=/etc/gated
else
	GATED_PIDFILE=/var/run/gated.pid
	GATED_VERSFILE=/var/run/gated.version
	GATED_DATA_DIR=/var/tmp
	GATED_DAEMON=/usr/sbin/gated
fi

if [ -f $GATED_PIDFILE ]
then
	GATED_PID=$(cat $GATED_PIDFILE)

	for PID in $(ps -e | grep gated | awk '{print $1}')
	do
		if [ $PID -eq $GATED_PID ]
		then
			GATED_RUNNING=YES
		fi
	done
fi

if [[ $GATED_RUNNING = YES ]]
then
	display_daemon gated
	kill -2 $GATED_PID
	sleep 5
else
	print
	print
	print "There is no \"$GATED_DAEMON\" process running on this system"
	print
	print
fi


#
# Call display_daemon looking for the sendmail process.  Depending on
# OS version, collect sendmail.cf/syslog file.
#
title "Sendmail Information"
display_daemon sendmail

if [ $OS_VERSION -lt 10 ]
then
	MAIL_STAT_FILE=/usr/lib/sendmail.st
else
	MAIL_STAT_FILE=/etc/mail/sendmail.st
fi

if [ -f $MAIL_STAT_FILE ]
then
	execute mailstats
fi


#
# Since we will be sending kill signals, we want to make sure we are
# sending them to a valid named process.  The named.pid file
# contains the PID number of the currently running (or last run)
# named process.  Use 'ps' to check for a running named process and
# make sure the process number matches the contents of the named.pid
# file before sending kills.
#
# Until we are sure named is running we assume it is not.
#
title "Domain Name System Configuration"
NAMED_RUNNING=NO

if [ $OS_VERSION -lt 10 ]
then
	NAMED_PIDFILE=/etc/named.pid
	NAMED_TEMP_DIR=/usr/tmp
	NAMED_DAEMON=/etc/named
else
	NAMED_PIDFILE=/var/run/named.pid
	NAMED_TEMP_DIR=/var/tmp
	NAMED_DAEMON=/usr/sbin/named
fi

if [ -f $NAMED_PIDFILE ]
then
	NAMED_PID=$(cat $NAMED_PIDFILE)

	for PID in $(ps -e | grep named | awk '{print $1}')
	do
		if [ $PID -eq $NAMED_PID ]
		then
			NAMED_RUNNING=YES
		fi
	done
fi

#
# If we have determined that named is running, send the process id a
# SIGINT and SIGIOT to get named to dump it's internal tables and
# statistics.  Sleep for a few seconds to allow the dumping processes
# to complete then collect the logfiles.
#
if [[ $NAMED_RUNNING = YES ]]
then
	display_daemon named
	kill -2 $NAMED_PID
	kill -6 $NAMED_PID
	sleep 5
else
	print
	print
	print "There is no \"$NAMED_DAEMON\" process running on this system"
	print
	print
fi

#
# If named is running, we will try to collect the DNS include files.
# The name of the directory that holds these files is contained in the
# named.boot file.  This file is normally named '/etc/named.boot' but
# the user can override this using the '-b' option on the named
# command line.  So, we will first check the running daemon to see
# if a '-b' option was specified.  If not, get the directory path
# from the '/etc/named.boot' file.
#
# We use 'ps' and 'grep' to find the named process and remove any
# line with "grep" in it returned by 'ps'.  We will use 'sed' to
# isolate the command portion of the 'ps' output.  We then use
# 'awk' to check for a "-b" on the command line and isolate the
# bootfile if one was specified.
#
if [[ $NAMED_RUNNING = YES ]]
then
	NAMED_BOOT=$(ps -ef | grep named | grep -v grep | \
		     sed 's/^.*[0-9] \//\//' | awk -F-b '{print $2}')

	if [[ -z $NAMED_BOOT ]]
	then
		NAMED_BOOT=/etc/named.boot
	fi

	cat_file $NAMED_BOOT
fi

#
# Print resolv.conf file
#
cat_file /etc/resolv.conf
}


function LMU_Info {

bigtitle "LAN Manager for Unix (LMU) Information"

if [ $OS_VERSION -lt 10 ]
then
	FILESETS="LMU"
	verify_fileset LMU $FILESETS

	if [ $? -ne 0 ]
	then
		return
	fi

	what_fileset $FILESETS
else
	PRODUCTS="LMU LMU-WAN-EXT RFC-NETBIOS"
	what_products LMU $PRODUCTS
	
	if [ $? -ne 0 ]
	then
		return
	fi
fi


#
# Print nbconfig file
#
title "NetBIOS Configuration"
if [ $OS_VERSION -lt 10 ]
then
	cat_file /etc/netbios/nbconfig
else
	cat_file /etc/opt/lmu/netbios/nbconfig
fi


#
# If the netdemon is running, call 'nbmem' to collect information on
# links, names and sessions.
#
title "NBMEM Information"
display_daemon netdemon

if [ $? -gt 0 ]
then
	execute nbmem links
	execute nbmem names
	execute nbmem sessions
fi


#
# Print lanman.ini file
#
title "LAN Manager for Unix Initialization"
if [ $OS_VERSION -lt 10 ]
then
	cat_file /usr/net/servers/lanman/lanman.ini
else
	cat_file /etc/opt/lmu/lanman/lanman.ini
fi


#
# Call 'lmshare' to collect share information
#
title "LAN Manager for Unix Share Information"
execute lmshare -l


#
# Call 'lmu_ver' to collect version information
#
title "LAN Manager for Unix Version Information"
execute lmu_ver


#
# If the lmx.ctrl daemon is running, call 'lmstat' and 'net' to collect
# various LMU configuration info
#
title "LAN Manager for Unix Service Configuration"
display_daemon lmx.ctrl

if [ $? -gt 0 ]
then
	execute lmstat -c
	execute net start
	execute net accounts
	execute net error
	execute net status
	execute net session
	execute net user
	execute net access
	execute net view
	execute net print
fi
}


function LMX_Info {

bigtitle "LAN Manager/X Information"

if [ $OS_VERSION -lt 10 ]
then
	FILESETS="LM_RUN"
	verify_fileset LMX $FILESETS

	if [ $? -ne 0 ]
	then
		return
	fi

	what_fileset $FILESETS
else
	PRODUCTS="LM-RUN"
	what_products LMX $PRODUCTS
	
	if [ $? -ne 0 ]
	then
		return
	fi
fi


#
# If NetBIOS_Daemon is running, display it.  Then look for the string
# NetBIOS_Daemon in lmdaem.conf.
#
title "NetBIOS Information"
display_daemon NetBIOS_Daemon

if [ $OS_VERSION -lt 10 ]
then
	LMDAEM_CONF=/usr/lib/lm/lmdaem.conf
else
	LMDAEM_CONF=/etc/opt/lmx/lmdaem.conf
fi

if [ -f $LMDAEM_CONF ]
then
	execute grep "NetBIOS_Daemon $LMDAEM_CONF"
else
	print
	print
	print "The file \"$LMDAEM_CONF\" does not exist"
	print
	print
fi


#
# Print lanmanx.ini file
#
title "LAN Manager/X Server Configuration"
if [ $OS_VERSION -lt 10 ]
then
	cat_file /usr/lib/lm/lanmanx.ini
else
	cat_file /etc/opt/lmx/lanmanx.ini
fi


#
# Print setup.pro/setup.shutdown file
#
title "LAN Manager/X Profile Information"
if [ $OS_VERSION -lt 10 ]
then
	cat_file /usr/lib/lm/profiles/setup.pro
else
	cat_file /etc/opt/lmx/profiles/setup.shutdown
fi


#
# If the LmLoop daemon is running, display it.  Call 'net' to collect
# various LMX configuration information
#
title "LAN Manager/X Service Configuration"
display_daemon LmLoop

if [ $? -gt 0 ]
then
	execute net error
	execute net status
	execute net session
	execute net view
	execute net print
fi


#
# Print a list of the home directories for users on this system.
# Use awk to extract the directory name.  Use ll to
# print the directory entry.  Use uniq to extract unique
# entries.  Finally use sort to alphabetize the list.
#
title "Home Directory Permissions"
cat /etc/passwd | awk -F: '{print $6}' | sort -k9 | uniq | while read DIRNAME
do
	ll -d $DIRNAME
done


#
# Print list of files in lmx directory
#
title "LAN Manager/X Files"
if [ $OS_VERSION -lt 10 ]
then
	list_dir /usr/lib/lm -li
else
	list_dir /opt/lmx/lanman/bin -li
fi
}


function NETWARE_Info {

bigtitle "Netware/9000 Information"

if [ $OS_VERSION -lt 10 ]
then
	FILESETS="NW-CMDS"
	verify_fileset NETWARE $FILESETS

	if [ $? -ne 0 ]
	then
		return
	fi

	what_fileset $FILESETS
else
	PRODUCTS="NetWare312-BIN"
	what_products NetWare312 $PRODUCTS
	
	if [ $? -ne 0 ]
	then
		return
	fi
fi


#
# List files in netware directories.  Also, print contents of various
# files in netware directory.
#
title "NetWare Configuration Files"
if [ $OS_VERSION -lt 10 ]
then
	list_dir /usr/netware/bin -li
	list_dir /etc/netware -li
else
	list_dir /opt/netware/bin -li
	list_dir /etc/opt/netware -li
fi

if [ $OS_VERSION -lt 10 ]
then
	if [ -d /etc/netware ]
	then
		cat_file /etc/netware/NPSConfig
		cat_file /etc/netware/NWConfig
		cat_file /etc/netware/PRTConfig
		cat_file /etc/netware/RPControl
		cat_file /etc/netware/RPConfig
	fi
else
	if [ -d /etc/opt/netware ]
	then
		cat_file /etc/opt/netware/npsconfig
		cat_file /etc/opt/netware/NWConfig
		cat_file /etc/opt/netware/PRTConfig
		cat_file /etc/opt/netware/RPControl
		cat_file /etc/opt/netware/RPConfig
	fi
fi


#
# Print the contents of any .pid files in the netware directory.
#
title "NetWare PID Files"
if [ $OS_VERSION -lt 10 ]
then
	PID_DIR=/etc/netware
else
	PID_DIR=/etc/opt/netware
fi

if [ -f $PID_DIR/*.pid ]
then
	ls -1 $PID_DIR/*.pid | while read PID
	do
		cat_file "$PID"
	done
fi


#
# If the netware sys$log.err file exists, print the last 200 lines
#
title "NetWare Error Log"
if [ $OS_VERSION -lt 10 ]
then
	SYSLOG_ERR=/usr/netware/sys/system/sys\$log.err
else
	SYSLOG_ERR=/var/opt/netware/sys/system/sys\$log.err
fi

if [ -f $SYSLOG_ERR ]
then
	execute tail "-200 $SYSLOG_ERR"
else
	print
	print
	print "The file \"$SYSLOG_ERR\" does not exist"
	print
	print
fi


#
# Run strings against the file netware binary.  Look for any lines
# containing the string "NetWare ".
#
title "NetWare Version Strings"
COMMAND=netware
if [[ ! -z $(whence $COMMAND) ]]
then
	execute $COMMAND "" \
	"Lines containing string \"NetWare \" in $(whence $COMMAND):" \
	grep "NetWare " <<-EOF
	$(strings $(whence $COMMAND))
	EOF
else
	print
	print
	print "The command \"$COMMAND\" is not executable"
	print
	print
fi


#
# If the npsd daemon is running, display it.  Then check to see if there
# is a NetWare daemon running.  If there is, the local system is the NetWare
# server.  If not, there is another NetWare server providing services for
# this system.  In either case, issue netware commands to collect output.
#
title "NetWare Server Information"
if [ $OS_VERSION -lt 10 ]
then
	display_daemon npsd
else
	display_daemon IPX
	display_daemon NVT
fi

if [ $? -gt 0 ]
then
	display_daemon NetWare

	if [ $? -eq 0 ]
	then
		print
		print
		print "The NetWare for UNIX server is NOT running."
		print "The following information is being provided by"
		print "another NetWare server."
		print
		print
	fi

	title "NetWare Server Configuration"

	execute userlist
	execute slist
	execute pslist

	title "NetWare Transport Information"

	execute drouter
	execute getlan
fi
}


function NFS_NIS_Info {

bigtitle "NFS Information"

if [ $OS_VERSION -lt 10 ]
then
	FILESETS="NFS-RUN"
	verify_fileset NFS $FILESETS

	if [ $? -ne 0 ]
	then
		return
	fi

	what_fileset $FILESETS
else
	PRODUCTS="NFS-CLIENT NFS-CORE NFS-PRG NFS-SERVER NIS-CLIENT NIS-SERVER"
	what_products NFS $PRODUCTS
	
	if [ $? -ne 0 ]
	then
		return
	fi
fi


#
# Call 'adb' to display value of 'nobody' variable
#
if [ $OS_VERSION -lt 9 ]
then
	title "NFS \"nobody\" Variable (Anonymous/Root User Access)"
	execute adb "" \
	"Output from print \"nobody/D\" | $(whence adb) /hp-ux /dev/kmem:" \
	adb /hp-ux /dev/kmem <<-EOF
	nobody/D
	EOF
fi


#
# Print exports file then call 'exportfs' to print the kernels list
# of exported filesystems
#
title "Exported and Mounted Filesystems"
cat_file /etc/exports

if [ $OS_VERSION -gt 8 ]
then
	execute exportfs
fi

#
# Call showmount -a to list the clients that have mounted any of our
# exported filesystems.
#
execute showmount -a

#
# Print rmtab file
#
cat_file /etc/rmtab

#
# If /etc/netgroup exists print it
#
cat_file /etc/netgroup


#
# Display the running nfsds.  Exclude the pcnsfd if found.
#
title "NFS Daemon Information"
display_daemon nfsd pcnfsd

#
# Display the running biods
#
display_daemon biod

#
# Display the running pcnfsds
#
display_daemon pcnfsd

#
# Print pcnfsd.conf file
#
cat_file /etc/pcnfsd.conf


bigtitle "NIS Information"

#
# Check the variable NIS_MASTER_SERVER in nfs configuration file.
# If it is set to 1, we are a master NIS server.
#
if [ $OS_VERSION -lt 10 ]
then
	FILE=/etc/netnfsrc
else
	FILE=/etc/rc.config.d/namesvrs
fi

is_nis_master=$(grep ^NIS_MASTER_SERVER= $FILE | awk -F= '{print $2}' | \
	        sed 's/\"//g')
if [[ ! -z $is_nis_master ]] && [ $is_nis_master -eq 1 ]
then
	NIS_SERVER="YES"
	print "This system is configured to be an NIS MASTER SERVER"
fi

#
# Check the variable NIS_SLAVE_SERVER in nfs configuration file.
# If it is set to 1, we are a slave NIS server.
#
is_nis_slave=$(grep ^NIS_SLAVE_SERVER= $FILE | awk -F= '{print $2}' | \
	       sed 's/\"//g')
if [[ ! -z $is_nis_slave ]] && [ $is_nis_slave -eq 1 ]
then
	NIS_SERVER="YES"
	print "This system is configured to be an NIS SLAVE SERVER"
fi

#
# Check the variable NIS_CLIENT in nfs configuration file.
# If it is set to 1, we are an NIS client.
#
is_nis_client=$(grep ^NIS_CLIENT= $FILE | awk -F= '{print $2}' | \
	        sed 's/\"//g')
if [[ ! -z $is_nis_client ]] && [ $is_nis_client -eq 1 ]
then
	NIS_CLIENT="YES"
	print "This system is configured to be an NIS CLIENT"
fi

#
# Call 'domainname' to see if the domainname has been set.  If so,
# display it and set NIS_CLIENT to "YES" just in case the above
# tests were not able to accurately determine if NIS is enabled.
# I've seen cases where customers remove the NIS_CLIENT variables
# from the netnfsrc scripts and we didn't collect NIS data even
# though NIS was enabled on the system.
#
# If it is not set, then set NIS_CLIENT and NIS_SERVER
# to "NO" and don't collect any NIS data.
#
if [[ ! -z $(domainname) ]]
then
	execute domainname
	NIS_CLIENT="YES"
else
	NIS_CLIENT="NO"
	NIS_SERVER="NO"
	print
	print
	print "The NIS domainname has not been set on this system"
	print "No Network Information Service data will be collected"
	print
	print
fi

#
# Call 'ypwhich' to see who we are currently bound to
#
if [[ $NIS_CLIENT = YES ]]
then
	execute ypwhich
fi

#
# Display the running ypserv and ypbind daemons.
#
if [[ $NIS_CLIENT = YES ]]
then
	title "NIS Daemon Information"

	display_daemon ypserv
	display_daemon ypbind
fi

#
# If we previously determined that we are an NIS Server of some type,
# call 'ls -F' to look for any directories under yp map directory.  These
# directories could be names of domains, in which case, the files in
# the directories would be the maps we are serving.  For each
# directory we find, call 'makedbm -u' and look for a valid ypservers
# map.  If this call completes successfully, we have found a set of
# NIS maps.  Call 'makedbm -u ypservers' again to print the current list
# of servers for this domain.
#
if [ $OS_VERSION -lt 10 ]
then
	DIR=/usr/etc/yp
else
	DIR=/var/yp
fi

if [[ $NIS_SERVER = YES ]]
then
	title "NIS YPServers Map Information"
	for DOMAIN in $(ls -F $DIR | grep \/ | sed 's/\///')
	do
		execute makedbm "-u $DIR/$DOMAIN/ypservers" > /dev/null 2>&1
		if [ $? -eq 0 ]
		then
			execute makedbm "-u $DIR/$DOMAIN/ypservers" \
			"Contents of the ypservers map for the \"$DOMAIN\" domain:"
		fi
	done
fi

#
# If we previously determined that we are an NIS Server of some type,
# call 'ls -F' to look for any directories under yp map directory.  These
# directories could be names of domains, in which case, the files in
# the directories would be the maps we are serving.  For each
# directory we find, call 'makedbm -u' and look for a valid ypservers
# map.  If this call completes successfully, we have found a set of
# NIS maps.  Call 'ypwhich' for this domain to print the current list
# of maps as well as the master server for this domain.  This will
# also show whether we are able to bind to the master of this domain.
#
if [ $OS_VERSION -lt 10 ]
then
	DIR=/usr/etc/yp
else
	DIR=/var/yp
fi

if [[ $NIS_SERVER = YES ]]
then
	title "NIS Map Information"
	for DOMAIN in $(ls -F $DIR | grep \/ | sed 's/\///')
	do
		execute makedbm "-u $DIR/$DOMAIN/ypservers" > /dev/null 2>&1
		if [ $? -eq 0 ]
		then
			execute ypwhich "-d $DOMAIN -m" \
			"This system is a SERVER in the \"$DOMAIN\" domain.\nThe following maps are served by this host:"
		fi
	done
fi

#
# If we previously determined that we are an NIS Client, call 'ypwhich' to
# print the current list of maps as well as the master for the domain.
# Next, we will create the temporary file $NIS_MAPS.  For each map name
# returned by ypwhich, we will call 'ypcat -k' and redirect the output to
# $NIS_MAPS.  This $NIS_MAPS file will be shar'd up by the collect_logfiles()
# function at the end of the script.
#
if [[ $NIS_CLIENT = YES ]]
then
	execute ypwhich -m \
	"This system is a CLIENT using the following maps:"

	bigtitle "NIS Maps for Domain: $(domainname)" > $NIS_MAPS
	for MAPNAME in $(ypwhich -m | awk '{print $1}')
	do
		execute ypcat "-k $MAPNAME" "Map Name: $MAPNAME" >> $NIS_MAPS
	done

	print
	print
	print "The contents of these CLIENT NIS maps was saved in file: client.nismaps"
	print
	print
	print
fi


#
# Print the securenets/secureservers files
#
title "Securenets/Secureservers Configuration Information"
if [ $OS_VERSION -lt 10 ]
then
	DIR=/etc
else
	DIR=/var/yp
fi
cat_file $DIR/securenets
cat_file $DIR/secureservers


#
# Display the running automount daemons.
#
title "Automount Information"
display_daemon automount

#
# Attempt to collect automount map information.  This can be a
# complicated matter since there are so many command line options
# to automount.  NIS could be involved, and the command line could
# be so long that the options we would search for could have scrolled
# out of the buffer checked by ps.  This section of the script should
# probably be enhanced at some point to do a more thorough search for
# map information.
#
# For now we will look in the most common places for the maps.  We
# will start by looking for an auto.master map.  We will first check NIS
# (which is the default), then we will look in /etc.
#
cat /dev/null > $TMPFILE1
cat /dev/null > $TMPFILE2

if [[ $NIS_CLIENT = YES ]]
then
	execute ypcat "-k auto.master" > /dev/null 2>&1
       	if [ $? -eq 0 ]
       	then
		execute ypcat "-k auto.master" \
		"This \"auto.master\" file is being managed by NIS:"
		execute ypcat "-k auto.master" NO >> $TMPFILE1
       	fi
fi

if [ $OS_VERSION -lt 10 ]
then
	FILE=/etc/auto.master
else
	FILE=$(grep ^AUTO_MASTER= /etc/rc.config.d/nfsconf | \
                                  awk -F= '{print $2}' | sed 's/\"//g')
fi
cat_file $FILE

if [ $? -eq 0 ]
then
	cat_file $FILE NO >> $TMPFILE1
fi

#
# Now that we have any and all auto.master information, look for any
# direct or indirect maps.  Use sed to filter out any lines beginning
# with '-hosts', '-passwd', '*', '#' or '+'.
#
if [ -f $TMPFILE1 ]
then
	sed -e '/-hosts/d' -e '/-passwd/d' -e '/*/d' -e '/#/d' \
            -e '/+/d' $TMPFILE1 | awk '{print $2}' > $TMPFILE2

	for MAP in $(grep \/ $TMPFILE2)
	do
		cat_file $MAP "Contents of Automount map \"$MAP\":"
	done

	if [[ $NIS_CLIENT = YES ]]
	then
		for NIS_MAP in $(sed '/\//d' $TMPFILE2)
		do
			execute ypcat "-k $NIS_MAP" \
			"Contents of NIS Automount map \"$NIS_MAP\":"
		done
	fi
fi

rm -f $TMPFILE1
rm -f $TMPFILE2


#
# Display the running rpc daemons.
#
title "RPC Information"
display_daemon rpc

#
# List the files in the status monitor directories.
#
if [ $OS_VERSION -lt 10 ]
then
	if [ -f /etc/state ]
	then
		cat_file /etc/state
	fi

	list_dir /etc/sm -l

	if [ -f /etc/sm/* ]
	then
		for FILE in $(ls -1 /etc/sm/*)
		do
			cat_file $FILE
		done
	fi

	list_dir /etc/sm.bak -l

	if [ -f /etc/sm.bak/* ]
	then
		for FILE in $(ls -1 /etc/sm.bak/*)
		do
			cat_file $FILE
		done
	fi
else
	if [ -f /var/statmon/state ]
	then
		cat_file /var/statmon/state
	fi

	list_dir /var/statmon/sm -l

	if [ -f /var/statmon/sm/* ]
	then
		for FILE in $(ls -1 /var/statmon/sm/*)
		do
			cat_file $FILE
		done
	fi

	list_dir /var/statmon/sm.bak -l

	if [ -f /var/statmon/sm.bak/* ]
	then
		for FILE in $(ls -1 /var/statmon/sm.bak/*)
		do
			cat_file $FILE
		done
	fi
fi

#
# Call 'rpcinfo' to display the registered rpc programs.
#
execute rpcinfo "-p $(hostname)"

#
# Print rpc file
#
cat_file /etc/rpc

#
# Call 'nfsstat' to display the rpc and nfs statistics
#
execute nfsstat
}


function OTS_FTAM_Info {

bigtitle "OSI Transport (OTS) and FTAM Service"

if [ $OS_VERSION -lt 10 ]
then
	FILESETS="OTS-RUN OTS-KRN"
	verify_fileset OTS $FILESETS

	if [ $? -ne 0 ]
	then
		return
	fi

	what_fileset $FILESETS
else
	print
	print
	print "OSI Collection is not yet available for 10.0"
	print
	print

	return
fi


#
# Call various OTS/FTAM configuration commands to collect output
#
title "OTS Configuration Information"
execute osistat
execute otsstat
execute osiconfchk -bd


#
# Call bin2conf to obtain the names of the subnets configured for OTS.
# Once the subnet names are determined, we call otsshowes, otsshowis and
# otsshowroute and pass the subnet name.
#
title "OTS Subnet Configuration"
cat /dev/null > $TMPFILE1
cat /dev/null > $TMPFILE2

bin2conf ots_subnets | grep snet\_c | sed '/#/d' >> $TMPFILE1
grep snet_clns_8023 $TMPFILE1 >> $TMPFILE2
grep snet_clns_fddi $TMPFILE1 >> $TMPFILE2
grep snet_clns_x25  $TMPFILE1 >> $TMPFILE2
grep snet_cons_x25  $TMPFILE1 >> $TMPFILE2

for SUBNET in $(awk '{print $2}' $TMPFILE2)
do
	execute otsshowes $SUBNET
	execute otsshowis $SUBNET
	execute otsshowroute $SUBNET
done

rm -f $TMPFILE1
rm -f $TMPFILE2
}


function SLIP_Info {

bigtitle "SLIP Information"

if [ $OS_VERSION -lt 10 ]
then
	FILESETS="SLIP-RUN"
	verify_fileset SLIP $FILESETS

	if [ $? -ne 0 ]
	then
		return
	fi

	what_fileset $FILESETS
fi


#
# Call 'pplstat' to collect connection information for all ppls.
# The ppl program writes into the ptmp file so this file must
# exist for pplstat to work.
#
title "SLIP Status Information"
if [ $OS_VERSION -lt 10 ]
then
	FILE=/usr/spool/ppl/ptmp
else
	FILE=/var/ppl/ptmp
fi

if [ -f $FILE ]
then
	execute pplstat "-l -n"
else
	print
	print
	print "The file \"$FILE\" does not exist"
	print
	print
fi

}


function SNAP_Info {

bigtitle "SNA Plus Information"

if [ $OS_VERSION -lt 10 ]
then
	FILESETS="SNAP-COMMON"
	verify_fileset SNAP $FILESETS

	if [ $? -ne 0 ]
	then
		return
	fi

	what_fileset $FILESETS
else
	print
	print
	print "SNAP Collection is not yet available for 10.0"
	print
	print

	return
fi


#
# Call snapwhat to collect version information
#
title "SNA Plus Version Information"
execute snapwhat


#
# If the com.cfg file exists, add it to the SNAP_FILES
# file.  Any file listed in SNAP_FILES will be collected by the
# collect_logfiles() function at the end of the script.
#
title "SNA Plus File Collection"
SNAPDIR=/usr/lib/sna

cat_file $SNAPDIR/com.cfg 

#
# If the sna.aud file exists, add it to the SNAP_FILES file.
#
cat_file $SNAPDIR/sna.aud

#
# If the sna.err file exists, add it to the SNAP_FILES file.
#
cat_file $SNAPDIR/sna.err

#
# If there are any snaMsg? files add them to the SNAP_FILES file.
#
for FILE in $(ls $SNAPDIR/snaMsg?)
do
cat_file $FILE
done 

#
# If there are any snafile?.trc files add them to the SNAP_FILES file.
#
for FILE in $(ls $SNAPDIR/snafile?.trc)
do
cat_file $FILE
done
}


function TIO_DTC_Info {

bigtitle "Term IO / DTC Information"

if [ $OS_VERSION -lt 10 ]
then
	FILESETS="ARPA-AUX DTCMGR"
	verify_fileset TIO $FILESETS

	if [ $? -ne 0 ]
	then
		return
	fi

	what_fileset $FILESETS
else
	print
	print
	print "Term IO Collection is not yet available for 10.0"
	print
	print

	return
fi


#
# DTC Manager/UX Code Version
#
title "DTC Code Versions"
if [ $OS_VERSION -lt 10 ]
then
	execute what "/usr/dtcmgr/code/*"
else
	execute what "/opt/dtcmgr/code/*"
fi


#
# If dtclist.log exists print it
#
title "DTC Logfile Information"
if [ $OS_VERSION -lt 10 ]
then
	cat_file /usr/adm/dtclist.log
else
	cat_file /var/opt/dtcmgr/dtclist.log
fi


#
# If dtclist is executable call it to print the DTC configuration.
# If we are on an 8.X system, '-C' is unknown.
#
title "DTC Configuration Information"
COMMAND=dtclist
if [[ ! -z $(whence $COMMAND) ]]
then
	for DTC in $($COMMAND -c | awk '{print $1}')
	do
		execute $COMMAND "-ac $DTC"
	done

	if [ $OS_VERSION -gt 8 ]
	then
		execute $COMMAND -aC "DTC Logging Information"
	fi
else
	print
	print
	print "The command \"$COMMAND\" is not executable"
	print
	print
fi


#
# DDFA Nailed Devices and Printers Configuration
#
title "DDFA Configuration"
cat_file /etc/ddfa/dp

if [ -f /etc/ddfa/*pcf* ]
then
	for PCF in $(ls /etc/ddfa/*pcf*)
	do
		cat_file $PCF
	done
fi
}


function X25_Info {

bigtitle "X25 & X29 (PAD) Information"

if [ $OS_VERSION -lt 10 ]
then
	FILESETS="X25-COM X25-PA"
	verify_fileset X25 $FILESETS

	if [ $? -ne 0 ]
	then
		return
	fi

	what_fileset $FILESETS
else
	print
	print
	print "X25 Collection is not yet available for 10.0"
	print
	print

	return
fi


#
# If any x25 download files exist, call 'what' to get their version
#
title "X25 Download Versions"
execute what "/etc/x25/x25*down*"


#
# Call 'x25stat' to print the IP mapping tables
#
title "X25 IP to X121 Mapping Information"
execute x25stat -a


#
# For each x25 device file call 'x25stat' to make sure they are valid
# x25 devices.  If this call is successful, call 'x25stat' again.  The
# -x -s and -e parameters are not implemented on s300/400 systems.
#
title "X25 Statistics"
for CARD in $(ls /dev/x25_?)
do
	execute x25stat "-d $CARD" > /dev/null 2>&1
	if [ $? -eq 0 ]
	then
		execute x25stat "-c -d $CARD" \
		"X25 Configuration Information for $CARD:"

		execute x25stat "-d $CARD" \
		"Established Connections for $CARD:"
		
		if [ $SYSTEM_TYPE -eq 700 ] || [ $SYSTEM_TYPE -eq 800 ]
		then
			execute x25stat "-d $CARD -t -p -g -f -x -s -e"
		else
			execute x25stat "-d $CARD -t -p -g -f"
		fi
	fi
done


#
# Print x29hosts file
#
title "X29 Hosts Information"
cat_file /etc/x25/x29hosts


#
# Print x3config file
#
title "X3 Information"
cat_file /etc/x25/x3config
}


function NETTUNE_Info {

#
# This function was written to provide the same functionality that the
# 'nettune' command provides at 10.0.  It calls 'adb' and gets the
# current configured value for many networking related parameters.  It
# then formats and interprets the values and prints the results in a
# more readable format than plain 'adb' output.  It also prints out the
# default values for easy comparison.
#
# This function has been modified to print the data in a columns for
# easier interpretting.
#
cat /dev/null > $TMPFILE1
cat /dev/null > $TMPFILE2

execute adb "" NO adb /hp-ux /dev/kmem <<-EOF > $TMPFILE1
	arpt_killc/D
	arpt_killi/D
	unicast_time/D
	unicast_disabled/D
	rebroadcast_time/D
	ipDefaultTTL/u
	ipforwarding/D
	ipqmaxlen/D
	subnetsarelocal/D
	tcpmss/D
	tcp_recvspace/D
	tcp_sendspace/D
	tcpDefaultTTL/u
	tcp_keepidle/D
	tcp_keepintvl/D
	tcp_maxidle/D
	so_keepalive_default/D
	so_qlimit_max/D
	udpcksum/D
	kudp_checksumming/D
	udpDefaultTTL/u
	EOF
	
cat $TMPFILE1 | sed -e '/.*:$/d' -e '/not found/d' -e '/not supported/d' \
		    -e '/address expected/d' -e '/^$/d' > $TMPFILE2

print
print "Simulated nettune output for pre-10.0 systems:"
print
print
print "       NETTUNE              Associated               Current           Default"
print "        Name              Kernel Variable             Value             Value"
print "_____________________  ____________________  ________________________  _______"

KERNEL_VAR=arpt_killc
if [[ ! -z $(grep $KERNEL_VAR $TMPFILE2) ]]
then
	VAR_FULLNAME=arp_killcomplete
	DEFAULT=2400
	VALUE=$(grep $KERNEL_VAR $TMPFILE2 | awk -F: '{print $2}' | \
		sed -e 's/	//g')
	printf "%-21s  %-20s  %-24s  %-7s\n" $VAR_FULLNAME $KERNEL_VAR \
	       "$VALUE ($(($VALUE/2)) seconds)" $DEFAULT
fi

KERNEL_VAR=arpt_killi
if [[ ! -z $(grep $KERNEL_VAR $TMPFILE2) ]]
then
	VAR_FULLNAME=arp_killincomplete
	DEFAULT=1200
	VALUE=$(grep $KERNEL_VAR $TMPFILE2 | awk -F: '{print $2}' | \
		sed -e 's/	//g')
	printf "%-21s  %-20s  %-24s  %-7s\n" $VAR_FULLNAME $KERNEL_VAR \
	       "$VALUE ($(($VALUE/2)) seconds)" $DEFAULT
fi

KERNEL_VAR=unicast_time
if [[ ! -z $(grep $KERNEL_VAR $TMPFILE2) ]]
then
	VAR_FULLNAME=arp_unicast
	DEFAULT=600
	VALUE=$(grep $KERNEL_VAR $TMPFILE2 | awk -F: '{print $2}' | \
		sed -e 's/	//g')
	printf "%-21s  %-20s  %-24s  %-7s\n" $VAR_FULLNAME $KERNEL_VAR \
	       "$VALUE ($(($VALUE/2)) seconds)" $DEFAULT
fi

KERNEL_VAR=rebroadcast_time
if [[ ! -z $(grep $KERNEL_VAR $TMPFILE2) ]]
then
	VAR_FULLNAME=arp_rebroadcast
	DEFAULT=120
	VALUE=$(grep $KERNEL_VAR $TMPFILE2 | awk -F: '{print $2}' | \
		sed -e 's/	//g')
	printf "%-21s  %-20s  %-24s  %-7s\n" $VAR_FULLNAME $KERNEL_VAR \
	       "$VALUE ($(($VALUE/2)) seconds)" $DEFAULT
fi

KERNEL_VAR=unicast_disabled
if [[ ! -z $(grep $KERNEL_VAR $TMPFILE2) ]]
then
	VAR_FULLNAME=arp_unicast_disabled
	DEFAULT=0
	VALUE=$(grep $KERNEL_VAR $TMPFILE2 | awk -F: '{print $2}' | \
		sed -e 's/	//g')
	if [ $VALUE -eq 0 ]
	then
		FORMATTED_VALUE=disabled
	else
		FORMATTED_VALUE=enabled
	fi
	printf "%-21s  %-20s  %-24s  %-7s\n" $VAR_FULLNAME $KERNEL_VAR \
	       "$VALUE ($FORMATTED_VALUE)" $DEFAULT
fi

KERNEL_VAR=ipDefaultTTL
if [[ ! -z $(grep $KERNEL_VAR $TMPFILE2) ]]
then
	VAR_FULLNAME=ip_defaultttl
	DEFAULT=255
	VALUE=$(grep $KERNEL_VAR $TMPFILE2 | awk -F: '{print $2}' | \
		sed -e 's/	//g')
	printf "%-21s  %-20s  %-24s  %-7s\n" $VAR_FULLNAME $KERNEL_VAR \
	       "$(($VALUE>>8)) (hop count)" $DEFAULT
fi

KERNEL_VAR=ipforwarding
if [[ ! -z $(grep $KERNEL_VAR $TMPFILE2) ]]
then
	VAR_FULLNAME=ip_forwarding
	DEFAULT=1
	VALUE=$(grep $KERNEL_VAR $TMPFILE2 | awk -F: '{print $2}' | \
		sed -e 's/	//g')
	if [ $VALUE -eq 0 ]
	then
		FORMATTED_VALUE=disabled
	else
		FORMATTED_VALUE=enabled
	fi
	printf "%-21s  %-20s  %-24s  %-7s\n" $VAR_FULLNAME $KERNEL_VAR \
	       "$VALUE ($FORMATTED_VALUE)" $DEFAULT
fi

KERNEL_VAR=ipqmaxlen
if [[ ! -z $(grep $KERNEL_VAR $TMPFILE2) ]]
then
	VAR_FULLNAME=ip_intrqmax
	DEFAULT=50
	VALUE=$(grep $KERNEL_VAR $TMPFILE2 | awk -F: '{print $2}' | \
		sed -e 's/	//g')
	printf "%-21s  %-20s  %-24s  %-7s\n" $VAR_FULLNAME $KERNEL_VAR \
	       "$VALUE (entries)" $DEFAULT
fi

KERNEL_VAR=subnetsarelocal
if [[ ! -z $(grep $KERNEL_VAR $TMPFILE2) ]]
then
	VAR_FULLNAME=tcp_localsubnets
	DEFAULT=1
	VALUE=$(grep $KERNEL_VAR $TMPFILE2 | awk -F: '{print $2}' | \
		sed -e 's/	//g')
	if [ $VALUE -eq 0 ]
	then
		FORMATTED_VALUE=false
	else
		FORMATTED_VALUE=true
	fi
	printf "%-21s  %-20s  %-24s  %-7s\n" $VAR_FULLNAME $KERNEL_VAR \
	       "$VALUE ($FORMATTED_VALUE)" $DEFAULT
fi

KERNEL_VAR=tcpmss
if [[ ! -z $(grep $KERNEL_VAR $TMPFILE2) ]]
then
	VAR_FULLNAME=tcp_max_segment_size
	DEFAULT=536
	VALUE=$(grep $KERNEL_VAR $TMPFILE2 | awk -F: '{print $2}' | \
		sed -e 's/	//g')
	printf "%-21s  %-20s  %-24s  %-7s\n" $VAR_FULLNAME $KERNEL_VAR \
	       "$VALUE (bytes)" $DEFAULT
fi

KERNEL_VAR=tcp_recvspace
if [[ ! -z $(grep $KERNEL_VAR $TMPFILE2) ]]
then
	VAR_FULLNAME=tcp_receive
	DEFAULT=8192
	VALUE=$(grep $KERNEL_VAR $TMPFILE2 | awk -F: '{print $2}' | \
		sed -e 's/	//g')
	printf "%-21s  %-20s  %-24s  %-7s\n" $VAR_FULLNAME $KERNEL_VAR \
	       "$VALUE (bytes)" $DEFAULT
fi

KERNEL_VAR=tcp_sendspace
if [[ ! -z $(grep $KERNEL_VAR $TMPFILE2) ]]
then
	VAR_FULLNAME=tcp_send
	DEFAULT=8192
	VALUE=$(grep $KERNEL_VAR $TMPFILE2 | awk -F: '{print $2}' | \
		sed -e 's/	//g')
	printf "%-21s  %-20s  %-24s  %-7s\n" $VAR_FULLNAME $KERNEL_VAR \
	       "$VALUE (bytes)" $DEFAULT
fi

KERNEL_VAR=tcpDefaultTTL
if [[ ! -z $(grep $KERNEL_VAR $TMPFILE2) ]]
then
	VAR_FULLNAME=tcp_defaultttl
	DEFAULT=30
	VALUE=$(grep $KERNEL_VAR $TMPFILE2 | awk -F: '{print $2}' | \
		sed -e 's/	//g')
	printf "%-21s  %-20s  %-24s  %-7s\n" $VAR_FULLNAME $KERNEL_VAR \
	       "$(($VALUE>>8)) (hop count)" $DEFAULT
fi

KERNEL_VAR=tcp_keepidle
if [[ ! -z $(grep $KERNEL_VAR $TMPFILE2) ]]
then
	VAR_FULLNAME=tcp_keepstart
	DEFAULT=14400
	VALUE=$(grep $KERNEL_VAR $TMPFILE2 | awk -F: '{print $2}' | \
		sed -e 's/	//g')
	printf "%-21s  %-20s  %-24s  %-7s\n" $VAR_FULLNAME $KERNEL_VAR \
	       "$VALUE ($(($VALUE/2)) seconds)" $DEFAULT
fi

KERNEL_VAR=tcp_keepintvl
if [[ ! -z $(grep $KERNEL_VAR $TMPFILE2) ]]
then
	VAR_FULLNAME=tcp_keepfreq
	DEFAULT=150
	VALUE=$(grep $KERNEL_VAR $TMPFILE2 | awk -F: '{print $2}' | \
		sed -e 's/	//g')
	printf "%-21s  %-20s  %-24s  %-7s\n" $VAR_FULLNAME $KERNEL_VAR \
	       "$VALUE ($(($VALUE/2)) seconds)" $DEFAULT
fi

KERNEL_VAR=tcp_maxidle
if [[ ! -z $(grep $KERNEL_VAR $TMPFILE2) ]]
then
	VAR_FULLNAME=tcp_keepstop
	DEFAULT=1200
	VALUE=$(grep $KERNEL_VAR $TMPFILE2 | awk -F: '{print $2}' | \
		sed -e 's/	//g')
	printf "%-21s  %-20s  %-24s  %-7s\n" $VAR_FULLNAME $KERNEL_VAR \
	       "$VALUE ($(($VALUE/2)) seconds)" $DEFAULT
fi

KERNEL_VAR=so_keepalive_default
if [[ ! -z $(grep $KERNEL_VAR $TMPFILE2) ]]
then
	VAR_FULLNAME=so_keepalive_default
	DEFAULT=0
	VALUE=$(grep $KERNEL_VAR $TMPFILE2 | awk -F: '{print $2}' | \
		sed -e 's/	//g')
	if [ $VALUE -eq 0 ]
	then
		FORMATTED_VALUE=disabled
	else
		FORMATTED_VALUE=enabled
	fi
	printf "%-21s  %-20s  %-24s  %-7s\n" $VAR_FULLNAME $KERNEL_VAR \
	       "$VALUE ($FORMATTED_VALUE)" $DEFAULT
fi

KERNEL_VAR=so_qlimit_max
if [[ ! -z $(grep $KERNEL_VAR $TMPFILE2) ]]
then
	VAR_FULLNAME=listen_so_queue_limit
	DEFAULT=20
	SO_QLIMIT_MAX_DEFINED=TRUE
	VALUE=$(grep $KERNEL_VAR $TMPFILE2 | awk -F: '{print $2}' | \
		sed -e 's/	//g')
	if [ $VALUE -eq 0 ]
	then
		FORMATTED_VALUE=20
	else
		FORMATTED_VALUE=128
	fi
	printf "%-21s  %-20s  %-24s  %-7s\n" $VAR_FULLNAME $KERNEL_VAR \
	       "$FORMATTED_VALUE (entries)" $DEFAULT
else
	VAR_FULLNAME=listen_so_queue_limit
	DEFAULT=20
	SO_QLIMIT_MAX_DEFINED=FALSE
	printf "%-21s  %-20s  %-24s  %-7s\n" $VAR_FULLNAME $KERNEL_VAR \
	       "* undefined (20 entries)" $DEFAULT
fi

KERNEL_VAR=udpcksum
if [[ ! -z $(grep $KERNEL_VAR $TMPFILE2) ]]
then
	VAR_FULLNAME=udp_cksum
	DEFAULT=1
	VALUE=$(grep $KERNEL_VAR $TMPFILE2 | awk -F: '{print $2}' | \
		sed -e 's/	//g')
	if [ $VALUE -eq 0 ]
	then
		FORMATTED_VALUE=disabled
	else
		FORMATTED_VALUE=enabled
	fi
	printf "%-21s  %-20s  %-24s  %-7s\n" $VAR_FULLNAME $KERNEL_VAR \
	       "$VALUE ($FORMATTED_VALUE)" $DEFAULT
fi

KERNEL_VAR=kudp_checksumming
if [[ ! -z $(grep $KERNEL_VAR $TMPFILE2) ]]
then
	VAR_FULLNAME=nfs_checksumming
	DEFAULT=0
	VALUE=$(grep $KERNEL_VAR $TMPFILE2 | awk -F: '{print $2}' | \
		sed -e 's/	//g')
	if [ $VALUE -eq 0 ]
	then
		FORMATTED_VALUE=disabled
	else
		FORMATTED_VALUE=enabled
	fi
	printf "%-21s  %-20s  %-24s  %-7s\n" $VAR_FULLNAME $KERNEL_VAR \
	       "$VALUE ($FORMATTED_VALUE)" $DEFAULT
fi

KERNEL_VAR=udpDefaultTTL
if [[ ! -z $(grep $KERNEL_VAR $TMPFILE2) ]]
then
	VAR_FULLNAME=udp_defaultttl
	DEFAULT=30
	VALUE=$(grep $KERNEL_VAR $TMPFILE2 | awk -F: '{print $2}' | \
		sed -e 's/	//g')
	printf "%-21s  %-20s  %-24s  %-7s\n" $VAR_FULLNAME $KERNEL_VAR \
	       "$(($VALUE>>8)) (hop count)" $DEFAULT
fi

if [[ $SO_QLIMIT_MAX_DEFINED = FALSE ]]
then
	print
	print
	print " *  The \"so_qlimit_max\" variable was not found in the kernel"
	print "    so by default the listen socket queue limit is 20 entries."
	print "    This variable can added to the kernel by installing the"
	print "    latest Internet Transport Mega-Patch."
	print
else
	print
fi
}


function bigtitle {

#
# Print a large header to separate major sections of the report.  Center the
# line of text using the following logic: read each string passed in, pass
# it to 'wc' to count the characters in the string, divide it by 2 and
# subtract it from 36 (since the line of asterisks is 72 characters long).
# This will give us the number of blank spaces that need to preceed the
# string in order to center it against the line of asterisks.  Use an until
# loop to increase the variable holding the blanks.  Finally print the blank
# spaces followed by the string.
#
print ""
print "***********************************************************************"
print "***********************************************************************"
print "*******                                                         *******"

while [[ ! -z $1 ]]
do
	SPACES=""
	STRING=$1
	let BLANKS=$((36-$(print $STRING | wc -c)/2))
	until [ $BLANKS -lt 1 ]
	do
		SPACES="$SPACES "
		let BLANKS=$BLANKS-1
	done
	print "$SPACES$STRING"
	shift
done

print "*******                                                         *******"
print "***********************************************************************"
print "***********************************************************************"
print
print
}


function title {

#
# Print a smaller header to separate sub-sections of the report.  Use the same
# logic from bigtitle() to center the passed string against the lines of
# asterisks.
#
print
print
print "***********************************************************************"

while [[ ! -z $1 ]]
do
	SPACES=""
	STRING=$1
	let BLANKS=$((36-$(print $STRING | wc -c)/2))
	until [ $BLANKS -lt 1 ]
	do
		SPACES="$SPACES "
		let BLANKS=$BLANKS-1
	done
	print "$SPACES$STRING"
	shift
done

print "***********************************************************************"
print
print
}


function execute {

#
# Check to see if the command passed in $1 exists and is executable.
# Use argument $2 (if passed) as the options for the command.  If a
# third argument ($3) is passed, use it as the string to print instead
# of the default message.  If $3 is "NO" no message is printed.  If a
# fourth argument is passed, ($@) evaluate it.  If it is "NO" do not
# execute the command passed in $1.  This is useful when the string
# printed in $3 already contained the output from the command entered
# in $1.  If $4 is not "NO" execute the command passed in $4 instead
# of $1.  This is useful for executing complex commands such as
# searching for dfile data with adb.
#
# If either the command in $1 or $4 fails to execute correctly, set
# variable COMMAND_FAILED to "YES" so that status 1 will be returned
# to the calling process.
#
COMMAND=$1

if [ $# -gt 1 ]
then
	ARGS=$2
else
	ARGS=""
fi

if [ $# -gt 2 ]
then
	PRT_STRNG=$3
else
	PRT_STRNG=""
fi

if [ $# -gt 3 ]
then
	shift 3
	ALT_CMD=$@
else
	ALT_CMD=""
fi

COMMAND_FAILED="NO"

if [[ ! -z $(whence $COMMAND) ]]
then
	if [[ $PRT_STRNG = "" ]]
	then
		if [[ $ARGS = "" ]]
		then
			print
			print
			print "Output from $(whence $COMMAND):"
			print	
		else
			print
			print
			print "Output from $(whence $COMMAND) $ARGS:"
			print
		fi
	else
		if [[ $PRT_STRNG != NO ]]
		then
			print
			print
			print $PRT_STRNG
			print
		fi
	fi

	if [[ $ALT_CMD = "" ]]
	then
		$COMMAND $ARGS
		if [ $? -eq 1 ]
		then
			COMMAND_FAILED="YES"
		fi
		print
		print
	else
		if [[ $ALT_CMD != NO ]]
		then
			$ALT_CMD
			if [ $? -eq 1 ]
			then
				COMMAND_FAILED="YES"
			fi
			print
			print
		fi
	fi
else
	print
	print
	print "The command \"$COMMAND\" is not present on this system,"
	print "therefore, it cannot be executed."
	print
	return 1
fi

if [[ $COMMAND_FAILED = YES ]]
then
	return 1
fi
}


function list_dir {

#
# Check to see if the directory passed in exists.  If it does, use ll to
# list the contents of the directory.  Use argument $2 as the options for
# ll.  If a third argument is passed, use it as the string to print instead
# of the default message.  If $3 is "NO" then no message is printed.
#
DIR=$1

if [ $# -gt 1 ]
then
	ARGS=$2
else
	ARGS=""
fi

if [ $# -gt 2 ]
then
	PRT_STRNG=$3
else
	PRT_STRNG=""
fi

if [ -d $DIR ]
then
	if [[ $PRT_STRNG = "" ]]
	then
		print
		print
		print "Listing of directory $DIR:"
		print
	else
		if [[ $PRT_STRNG != NO ]]
		then
			print
			print
			print $PRT_STRNG
			print
		fi
	fi
	ls $ARGS $DIR
	print
	print
else
	print
	print
	print "The directory \"$DIR\" does not exist"
	print
	print
	return 1
fi
}


function cat_file {

#
# Check to see if the file passed in exists, and is a printable text
# file.  If it is, use cat to print the contents of the file.  If a
# second argument is passed, use # it as the string to print instead
# of the default message.  If $2 is "NO" then no message is printed.
#
FILE=$1

if [ $# -gt 1 ]
then
	PRT_STRNG=$2
else
	PRT_STRNG=""
fi

if [ -f "$FILE" ]
then
	if [[ ! -z $(file "$FILE" | egrep 'text|ascii|empty') ]]
	then
		if [[ $PRT_STRNG = "" ]]
		then
			print
			print
			print "Contents of $FILE:"
			print
		else
			if [[ $PRT_STRNG != NO ]]
			then
				print
				print
				print $PRT_STRNG
				print
			fi
		fi
		cat "$FILE"
		print
		print
	else
		print
		print
		print "The file \"$FILE\" is not a text file"
		print
		print
		return 1
	fi
else
	print
	print
	print "The file \"$FILE\" does not exist"
	print
	print
	return 1
fi
}


function what_fileset {

#
# For each fileset passed in $@ do the following: for each file in
# the fileset strip off all but the filename; call 'whence' to see if
# it is an executable in our path; then call 'what' to print version
# information for the file.
#
# New sed logic was added to make this function compatible with 3/400
# and 7/800 diskless environments.  The sed logic will strip out the
# strings +/HP-PA or +/HP-MC68020 from the fileset entry so that whence
# can correctly find the file.  The sed logic will also remove any
# lines from $TMPFILE2 that are not fully qualified.  This is needed
# in case any files in the /etc/fileset entry are the same as ksh
# built-in commands such as print, kill, exit, etc.
#
FILESETS=$@
DIR=/etc/filesets

for FILESET in $FILESETS
do
	cat /dev/null > $TMPFILE1
	cat /dev/null > $TMPFILE2

	cat $DIR/$FILESET | sed -e 's/\+\/HP-MC.....//' -e 's/\+\/HP-PA//' \
            -e 's/^.*\///' -e '/customize/d' | sort | uniq > $TMPFILE1

	for FILE in $(cat $TMPFILE1)
	do
		whence $FILE >> $TMPFILE2
	done

	title "Version of files in $FILESET"

	for FILE in $(cat $TMPFILE2 | sed '/\//!d')
	do
		execute what $FILE
	done
done

rm -f $TMPFILE1
rm -f $TMPFILE2
}


function what_products {

#
# This function is similar to what_fileset() and verify_fileset() but
# with modifications for 10.0 compatibility.
#
# The directory names of the subsystems will vary depending on whether
# 10.X was loaded during an update or an install.  Before we begin
# looking for the product directories we should check for variations
# on the SUBSYSTEM name.
#
# For each product directory passed in $@ do the following: check to make
# sure the directory exists; use grep, sed and awk to strip filenames out
# from the INFO file; call 'whence' to see if it is an executable in our
# path; then call 'what' to print version information for the file.
#
SUBSYSTEM=$1; shift
PRODUCT_FILES=$@
DIR=/var/adm/sw/products

if [ ! -d $DIR/$SUBSYSTEM ]
then
	print "The directory \"$DIR/$SUBSYSTEM\" does not exist."
	print "Checking for variations of the \"$SUBSYSTEM\" directory..."
	print
	print

	NEW_SUBSYSTEM=$(ls -1d $DIR/$SUBSYSTEM.[1-9] 2> /dev/null | \
			awk -F/ '{print $6}')

	if [[ ! -z $NEW_SUBSYSTEM ]] && [ -d $DIR/$NEW_SUBSYSTEM ]
	then
		print "Found replacement directory \"$DIR/$NEW_SUBSYSTEM\""
		SUBSYSTEM=$NEW_SUBSYSTEM
	else
		print "No variations found.  $SUBSYSTEM Information will not be collected."
		return 1
	fi
fi

for PRODUCT in $PRODUCT_FILES
do
	if [ -d $DIR/$SUBSYSTEM/$PRODUCT ]
	then
		cat /dev/null > $TMPFILE1
		cat /dev/null > $TMPFILE2

		cat $DIR/$SUBSYSTEM/$PRODUCT/INFO | sed -e '/path \//!d' \
                    -e 's/^.*\///' | sort | uniq > $TMPFILE1

		for FILE in $(cat $TMPFILE1)
		do
			whence $FILE >> $TMPFILE2
		done

		title "Version of files in $PRODUCT"

		for FILE in $(cat $TMPFILE2 | sed '/\//!d')
		do
			execute what $FILE
		done
	else
		print
		print
		print "The directory \"$DIR/$SUBSYSTEM/$PRODUCT\" does not exist."
		print
		print "Some $SUBSYSTEM Information may not be collected."
	fi
done

rm -f $TMPFILE1
rm -f $TMPFILE2
}


function verify_fileset {

#
# Check to see if the fileset file passed in $2 exists on the system.
# If it does, verify that all the files listed in the fileset exist
# on the system.  If the fileset doesn't exist, print an error message
# and return bad status (1) to the calling function.  The calling
# function should check this return status and quit if status = 1.
#
# If a fileset is missing, set FILESET_MISSING to "YES" so that a
# status of 1 will be returned to the calling process.
#
# New sed logic was added to make this function compatible with 3/400
# and 7/800 diskless environments.  The sed logic will strip out the
# strings +/HP-PA or +/HP-MC68020 from the fileset entry so that xargs
# can correctly find the file.
#
SUBSYSTEM=$1; shift
FILESETS=$@
DIR=/etc/filesets

FILESET_MISSING="NO"

for FILE in $FILESETS
do
	if [ -f $DIR/$FILE ]
	then
		print
		print
		print "Verifying contents of fileset $FILE..."
		print
		cat $DIR/$FILE | sed -e 's/\+\/HP-MC.....//' \
                    -e 's/\+\/HP-PA//' | xargs ls > /dev/null

		if [ $? = 0 ]
		then
			print "All files listed in \"$DIR/$FILE\" are installed."
			print
			print
		else
			print
			print "The above files are listed in \"$DIR/$FILE\" but were not found."
			print
			print
		fi
	else
		print
		print
		print "The file \"$DIR/$FILE\" does not exist."
		print
		print "$SUBSYSTEM Information will not be collected."
		print
		print
		FILESET_MISSING="YES"
	fi
done

if [[ $FILESET_MISSING = YES ]]
then
	return 1
fi
}


function display_daemon {

#
# Use ps to look for running daemon passed in as $1.  An exclusion
# string can be passed in as $2 if necessary.  In certain instances,
# the grep search will return information for daemons whose name is
# a superset of the requested daemon - nfsd & pcnfsd for example.  For
# this reason, if $2 is specified, use 'sed' to remove any lines
# matching the exclusion string.  This will leave only those lines
# matching the originally requested string.
#
# Then use 'sed' to remove the grep process and 'wc' to count the
# remaining lines.  Return the number of daemons found to the calling
# process in case it needs to know.
#
# If a third argument is passed, use it as the string to print instead
# of the default message.  If $3 is "NO" then no message is printed.
#
DAEMON=$1
EXCLUDE=$2

if [ $# -gt 2 ]
then
	PRT_STRNG=$3
else
	PRT_STRNG="YES"
fi

if [[ -z $EXCLUDE ]]
then
	num_daemons=$(ps -e | grep $DAEMON | wc -l)
else
	num_daemons=$(ps -e | grep $DAEMON | grep -v $EXCLUDE | wc -l)
fi

if [ $num_daemons -ne 0 ]
then
	if [[ $PRT_STRNG = YES ]]
	then
		print
		print
		print "The following \"$DAEMON\" process is currently running:"
		print
	else
		if [[ $PRT_STRNG != NO ]]
		then
			print
			print
			print $PRT_STRNG
			print
		fi
	fi

	if [[ ! -z $EXCLUDE ]]
	then
		ps -ef | grep $DAEMON | grep -v -e grep -e $EXCLUDE
	else
		ps -ef | grep $DAEMON | grep -v grep
	fi

	print
	print
else
	print
	print
	print "There is no \"$DAEMON\" process running on this system"
	print
	print
fi

return $num_daemons
}


function verify_null {

#
# Verify that file /dev/null is a character device file rather than a
# regular file.  If a regular file called /dev/null exists, remove it.
# Use 'mknod' to create the correct device file.
#
DEVICE=/dev/null

if [ ! -c $DEVICE ]
then
	bigtitle "Device File $DEVICE Verification"
	if [ -a $DEVICE ]
	then
		print "The file \"$DEVICE\" is not a character device file!"
		print
		print "This script will rename the existing \"$DEVICE\" and"
		print "create a new character device file in it's place."
		mv $DEVICE $DEVICE.old
		print
		print "The old \"$DEVICE\" file has been renamed as:"
		ls -l $DEVICE.old
		print
		print
	else
		print "The file \"$DEVICE\" does not exist on this system!"
		print
		print "This script will create a new character device file"
		print "called \"$DEVICE\" with default permissions."
		print
		print
	fi

	mknod $DEVICE c 3 0x000002
        chown bin $DEVICE
        chgrp bin $DEVICE
        chmod 666 $DEVICE

	print "The new \"$DEVICE\" file has been created as:"
	print
	ls -l $DEVICE
	print
	print
fi
}


function add_subsystem {

#
# Use expr to evaluate whether the requested SUBSYSTEM is already
# in the $SUB_SYSTEMS list.  Trying to avoid collecting data from the
# same subsystem more than once.  Even if the user mistakenly enters
# the same subsystem argument more than once on the command line,
# eliminate any duplicates.
#
SUBSYSTEM=$1

RESULT=$(expr "$SUB_SYSTEMS" : ".*\($SUBSYSTEM\).*")
if [[ -z $RESULT ]] || [ $RESULT -eq 0 ]
then
	SUB_SYSTEMS="$SUB_SYSTEMS $SUBSYSTEM"
fi
}


function remove_tmpfiles {

#
# If any temporary files created by this script still exist, remove them.
#
TMP_FILE_LIST="$ANALYZE_FILE $AUDIT_LOGS $CRON_JOBS $CRON_INFO $DIAG_LOGS $GATED_FILES $NAMED_FILES $NFS_FILES $NIS_MAPS $SLIP_FILES $SNAP_FILES $MAIL_FILES $RBOOTD_FILES $RC_FILES $SAR_FILE $SYS_FILES $TMPFILE1 $TMPFILE2 stm.log $GATED_DATA_DIR/gated_dump $NAMED_TEMP_DIR/named_dump.db $NAMED_TEMP_DIR/named.stats"

for FILE in $TMP_FILE_LIST
do
	if [ -f $FILE ]
	then
		rm -f $FILE
	fi
done
}


function get_args {

SUB_SYSTEMS="$ALL_SUB_SYSTEMS"
}


#############################################################################
#
#                          CAPTURE MAIN PROGRAM
#
#############################################################################

#
# Validate any arguments passed on the command line
#
get_args $*


#
# Verify that /dev/null exists as a character device file
#
verify_null

#
# Collect default information (os, hardware etc.) as well as those
# subsets of data requested on the command line.  For each entry in
# the SUB_SYSTEMS variable, call the associated "_Info" function to
# collect the data.
#
for SUBSYSTEM in $SUB_SYSTEMS
do
	"$SUBSYSTEM"_Info
done

#
# Remove any temporary files prior to building the shar file
#
remove_tmpfiles
print ""
}

lvmcollect_9()
{

###############################################################################
###############################################################################
#
# Function definitions.
#
###############################################################################
###############################################################################




f_Header()
  {

    # Display an header giving additional information and warnings.  
    #
    # The script revision number and run time are displayed.  The user is
    # warned that all the physical volumes should be on-line to create an
    # accurate picture of the Logical Volume Manager system configuration.


    echo "${SEPARATOR2}"
    echo "*******                                                                 *******"
    echo "*******        LOGICAL VOLUME MANAGER (LVM) SYSTEM CONFIGURATION        *******"
    echo "*******                                                                 *******"
    echo "*******                                                                 *******"
    echo "*******                                                                 *******"
    echo "${SEPARATOR2}"

    # Display the time that the script is ran.
    date
    
    # Display warning message.
    echo
    echo
    echo "WARNING:  All the physical volumes should be on-line while scanning"
    echo "          the Logical Volume Manager (LVM) system configuration."

  }




f_Index()
  {

    # Display the index to show what information will be retrieved.


    echo
    echo
    echo "${SEPARATOR}"
    echo
    echo "*****"
    echo "INDEX"
    echo "*****"

    echo
    echo
    echo "Part 1:  SYSTEM CONFIGURATION"
    echo "Part 2:  VOLUME GROUPS"
    echo "Part 3:  PHYSICAL VOLUME GROUPS"
    echo "Part 4:  LOGICAL VOLUMES"
    echo "Part 5:  PHYSICAL VOLUMES"
    echo "Part 6:  FILE SYSTEMS AND SWAP SPACE"
    echo "Part 7:  ROOT / PRIMARY SWAP / DUMPS / KERNEL CONFIGURATION"
    echo "Part 8:  LVM DEVICE FILES"
    echo "Part 9:  OTHER"

  }






f_SystemConf()
  {
    
    ###########################################################################
    # Part 1:  Your System's Hardware
    #          ----------------------
    #          The f_SystemConf() function will help you gather information 
    #          about the disks and other hardware on your system pertaining 
    #          to LVM.
    #
    #          It retrieves the following information:
    #
    #            + System an operating system:
    #              system name, machine hardware model name, machine
    #              identification number, operating system release, license
    #              level, amount of memory
    #
    #            + Disks configured:
    #              disk type, disk capacity, interface type, hardware address, 
    #              lu number, physical volumes, bootable physical volumes
    # 
    #            + LVM mirroring software
    #              whether the optional MirrorDisk/UX product is installed
    ###########################################################################
    

    echo
    echo
    echo ${SEPARATOR}
    echo
    echo "*****************************"
    echo "Part 1:  SYSTEM CONFIGURATION"
    echo "*****************************"
    
    
    # Identify the system type, operating system release and license level.
    
    SYSTEM_NAME=`uname -n`
    HW_MODEL=`uname -m`
    MACHINE_ID=`uname -i`
    OS_REL=`uname -r`
    OS_REL2=`grep fv /system/UX-CORE/index | sed -e 's/fv:[	 ]*//'`
    LICENSE_LEVEL=`uname -l`
    VERSION_LEVEL=`uname -v`
    
    echo
    echo
    echo "System and operating system"
    echo "***************************"
    echo
    echo "   System name                  : ${SYSTEM_NAME}"
    echo "   Machine hardware model name  : ${HW_MODEL}"
    echo "   Machine identification number: ${MACHINE_ID}"
    echo "   Operating system release     : ${OS_REL} (${OS_REL2})"
    echo "   License level                : ${LICENSE_LEVEL} (${VERSION_LEVEL})"
    
    
    # Determine the memory size.

    # Real memory expressed in units of pages (4 kbytes per page).
    REAL_MEM=`echo 'physmem/D'| adb /hp-ux /dev/kmem | tail -1 | \
              awk '{print $2}'`
    echo "   Real memory                  : `expr ${REAL_MEM} / 256` Mbytes"
    
    
    # Identify the hardware address and interface type for each disk on the 
    # system.
    
    echo
    echo
    echo "Disks configured"
    echo "****************"
    echo
    ioscan -fC disk | sed -e 's/^/   /'
    echo
    
    
    # Get additional information for each disk: product id, size, (bootable)
    # physical volume.
    echo "            LU  Product id   Size       PV   Bootable PV"
    echo "           =============================================\c"
    
    # Determine the lu numbers of all disk devices.
    LU_NUMBERS=`ioscan -fC disk | sed -e 1,2d  -e 's/^disk *//' | \
                  cut -f 1 -d " "`

    # NOTE:  Incorrect output may appear if there is a disk device in the
    #        system for which no lu number has been assigned yet.  In this
    #        case ioscan(1M) lists a '-' for the lu number.  The lu number is
    #        used in subsequent commands to retrieve more information about
    #        the disk, if the lu is a '-' --> ...  To avoid this, a test was 
    #        added to skip to the next lu number if a '-' is encountered.
    #
    #        Note also that a CD-ROM drive may answer nicely to diskinfo
    #        if there is no CD present.  Depending on the type of CD-ROM
    #        drive, the diskinfo(1M) command returns an error that the
    #        device cannot be opened.  For example, when using the diskinfo(1M)
    #        command on a XM-3301TA CD-ROM drive with no CD inserted, it will
    #        return the following error message: "diskinfo: can't open
    #        /dev/dsk/c<lu>d0s2: No such device or address" (return code 1).
    
    # Retrieve more information about the disks: product id, size, physical
    # volumes, bootable physical volumes.

    for LU_NUMBER in ${LU_NUMBERS}
      do
        # Skip to next if there is no lu number assigned.
        if [ ${LU_NUMBER} = "-" ]; then continue; fi 

        # Determine if the disk is a PV
        pvdisplay /dev/dsk/c${LU_NUMBER}d0s2 2>&1 | \
          grep -i pvdisplay > /dev/null 2>&1
        if [ $? -ne 0 ]
          then
    
            # The disk is a physical volume
            PV="yes"
    
            # Check if the physical volume is bootable.  A physical volume
            # is assumed to be bootable if it contains a LIF area, and the
            # LIF area contains the initial system loader (ISL).  This is not
            # full proof, but it will give a good indication in the normal
            # cases.  For more information about the LIF area, see the verbose
            # output of LVMcollect.

            lifls /dev/rdsk/c${LU_NUMBER}d0s2 2> /dev/null | \
              grep -i isl > /dev/null 2>&1
            if [ $? -eq 0 ]
              then
                # Bootable PV
                BOOTABLE_PV="yes"
              else
                # Non-bootable PV
                BOOTABLE_PV="no"
            fi
    
          else 
    
             # The disk is not recognized as a physical volume.
             PV="no"
             BOOTABLE_PV="-"
    
          fi
    
          # Filter out the hard disks, no information needs to be displayed for
          # other disk devices like CD-ROM's and cartridge tapes.
    
          # Cartridge tape drives and CD-ROM's may not respond nicely
          # to the diskinfo(1M) command !
          /etc/diskinfo /dev/rdsk/c${LU_NUMBER}d0s2 > ${TEMPFILE}
          if [ $? -eq 0 ]
            then
    
              PRODUCT_ID=`cat ${TEMPFILE} | grep -i product | \
                           sed -e 's/[ 	]*product id: \(.*\)/\1/' \
                               -e 's/[ 	]*$//'`
    
              SIZE=`cat ${TEMPFILE} | grep size | \
                     sed -e 's/[^0-9]*\([0-9][0-9]*\)[^0-9]*/\1/'`
    
              # Product id does not return nice for CD-ROM, spaces !  Print out
              # separated so that only the first part of the product id is
              # printed.
              echo ${LU_NUMBER} ${PRODUCT_ID} | \
                awk '{printf "\n\t   %3d  %8s", $1, $2}'
              echo `expr ${SIZE} / 1024` ${PV} ${BOOTABLE_PV} | \
                awk '{printf "   %4d Mbytes  %3s  %3s", $1, $2, $3}'
    
            else 
    
              echo ${LU_NUMBER} | \
                awk '{printf "\n\t    %2d  >> Error:  device probably not a disk <<", $1}'
    
          fi
          rm -f ${TEMPFILE}
      done
    echo

    echo "\n   Note:  All disk devices are listed here, not only hard disks."
    
    
    # Determine if the optional LVM mirroring software is installed.
    
    echo
    echo
    echo "LVM mirroring software"
    echo "**********************"
    echo
    
    if [ -f "/etc/filesets/LVM-MIRROR" ]
      then
        MIRROR="yes"
        echo "   LVM mirroring software MirrorDisk/UX (B2491A) is installed."
      else
        MIRROR="No"
        echo "   LVM mirroring software MirrorDisk/UX (B2491A) is NOT installed."
    fi

  }   




f_VolumeGroups()
  {
    
    ###########################################################################
    # Part 2:  The Volume Groups on Your System
    #          --------------------------------
    #          The f_VolumeGroups() function will help you identify the volume 
    #          groups on your system, and for each volume group:
    #
    #            + The physical volumes associated with the volume group.
    #
    #            + The volume group capacity: total, allocated, and free disk 
    #              space expressed in Mbytes and in physical extents.
    #
    #            + The volume group's physical extent size.
    ###########################################################################
    

    echo
    echo
    echo ${SEPARATOR}
    echo
    echo "**********************"
    echo "Part 2:  VOLUME GROUPS"
    echo "**********************"
    

    # Identify the volume groups and physical volumes.
    
    # Determine the volume group names.
    VG_NAMES=`vgdisplay | grep 'VG Name' | sed -e 's/VG Name[ 	]*//'`
    
    # Retrieve more information about each volume group: physical volumes, disk
    # space usage, physical extent size.
    for VG_NAME in ${VG_NAMES}
        do
          echo
          echo
          echo "Volume Group: ${VG_NAME}"
          echo "*************"
          echo
    
          # List all physical volumes in the volume group.
    
          echo "   Physical Volumes:"
          echo
          vgdisplay -v ${VG_NAME} | grep -i name | grep -iv lv | \
            grep -iv pvg | sed -e 1d | sed -e 's/.*\(\/.*\/.*\/.*\)/\1/' | \
            sort -u -k 1,1 | sed -e 's/^/   /'
          echo
    
          # Get disk space information for the volume group.
    
          PE_SIZE=`vgdisplay ${VG_NAME} | grep 'PE Size' | \
                    sed -e 's/^[^0-9]*\([0-9][0-9]*\)[ 	]*/\1/'`
          TOTAL_PE=`vgdisplay ${VG_NAME} | grep 'Total PE' | \
                     sed -e 's/^[^0-9]*\([0-9][0-9]*\)[ 	]*/\1/'`
          ALLOC_PE=`vgdisplay ${VG_NAME} | grep 'Alloc PE' | \
                     sed -e 's/^[^0-9]*\([0-9][0-9]*\)[ 	]*/\1/'`
          FREE_PE=`vgdisplay ${VG_NAME} | grep 'Free PE' | \
                     sed -e 's/^[^0-9]*\([0-9][0-9]*\)[ 	]*/\1/'`
    
          echo "   Volume group disk space usage:"
          echo
          echo `expr ${TOTAL_PE} \* ${PE_SIZE}` ${TOTAL_PE} | \
            awk '{printf "   Total    : %5d Mbytes  %5d PE\n", $1, $2}'
          echo `expr ${ALLOC_PE} \* ${PE_SIZE}` ${ALLOC_PE} | \
            awk '{printf "   Allocated: %5d Mbytes  %5d PE\n", $1, $2}'
          echo `expr ${FREE_PE} \* ${PE_SIZE}` ${FREE_PE} | \
            awk '{printf "   Free     : %5d Mbytes  %5d PE\n", $1, $2}'
          echo
          echo ${PE_SIZE} | \
            awk '{printf "   PE size  : %5d Mbytes", $1}'
          echo
        done
  }




f_PhysicalVolumeGroups()
  { 

    ###########################################################################
    # Part 3:  The Physical Volume Groups on Your System
    #          -----------------------------------------
    #          Physical volume groups are subgroups of LVM disks (physical
    #          volumes) within a volume group.  An ASCII file, /etc/lvmpvg 
    #          contains all the mapping information for the physical volume
    #          group, but the mapping is not recorded on the disk.
    #
    #          This part of the procedure will help you identify:
    #
    #            + For each volume group, the physical volume groups.
    #
    #            + For each physical volume group, the physical volumes.
    ###########################################################################
    

    echo
    echo
    echo ${SEPARATOR}
    echo
    echo "*******************************"
    echo "Part 3:  PHYSICAL VOLUME GROUPS"
    echo "*******************************"
    

    if [ -f /etc/lvmpvg ]
      then
        # Determine the volume group names.
        VG_NAMES=`vgdisplay | grep 'VG Name' | sed -e 's/VG Name[ 	]*//'`
    
        # For each volume group, show the physical volumes defined.

        # NOTE:  The existance of the /etc/lvmpvg file doesn't imply that
        #        there are physical volume groups defined for each volume
        #        group.  Catch the abscence and display an appropriate message.

        for VG_NAME in ${VG_NAMES}
          do
            echo
            echo
            echo "Volume Group: ${VG_NAME}"
            echo "*************"
            echo
            rm -f ${TEMPFILE} > /dev/null 2>&1
            vgdisplay -v ${VG_NAME} | \
              sed -n -e '/Physical volume groups/,$p' | \
              tee ${TEMPFILE} | \
              sed -e '1d' \
                  -e '$d' \
                  -e '$d' \
                  -e 's/.*PVG Name[     ]*/   Physical volume group: /' \
                  -e 's/.*PV Name[      ]*/   /'

            # The existance of the '/etc/lvmpvg' file doesn't imply that there 
            # are physical volume groups defined for each volume group.  Catch
            # the abscence and display an appropriate message.

            if [ ! -s ${TEMPFILE} ]
              then
                echo "No physical volume groups were defined for this volume group."
            fi
          done
    
      else

        # The '/etc/lvmpvg' file is missing.        
        echo 
        echo
        echo "No physical volume groups were defined, see lvmpvg(4)."

    fi


  }




f_LogicalVolumes()
  {

    ###########################################################################
    # Part 4:  The Logical Volumes on Your System
    #          ----------------------------------
    #          In part 2 of the procedure you identified the volume groups that 
    #          are defined on your system.  These are pools of disk space from
    #          which logical volumes (the LVM equivalent of disk sections) are 
    #          created.
    #
    #          The f_LogicalVolumes() function will help you identify:
    #          the logical volumes on your system, which volume groups they are
    #          part of, how big they are, the logical volume permissions, bad 
    #          block allocation policy, allocation policy, status, whether they
    #          are mirrored (single, or double) or not mirrored at all, 
    #          consistency recovery, scheduling policy.
    ###########################################################################
    

    echo
    echo
    echo ${SEPARATOR}
    echo
    echo "************************"
    echo "Part 4:  LOGICAL VOLUMES"
    echo "************************"
    
    
    # Determine the volume group names.
    VG_NAMES=`vgdisplay | grep 'VG Name' | sed -e 's/VG Name[ 	]*//'`

    # Identify volume groups and logical volumes.
    for VG_NAME in ${VG_NAMES}
      do
        echo
        echo
        echo "Volume Group: ${VG_NAME}"
        echo "*************"
        echo
  
        # Get a list of LV's in this VG
        LV_NAMES=`vgdisplay -v ${VG_NAME} | grep -i 'lv name' | \
              sed -e 's/.*\/.*\/.*\/\(.*\)/\1/'`
  
        echo "   Logical Volume  Size   PE B     Allocation        Status          Mirroring"
        echo "   Name            Mbytes RM B                                       #   CR  S"
        echo "   ==========================================================================="
  
        # Retrieve more information for each logical volume.
        for LV_NAME in ${LV_NAMES}
          do
            # Determine the logical volume's size.
            LV_SIZE=`lvdisplay ${VG_NAME}/${LV_NAME} | grep -i size | \
                      sed -e 's/[^0-9]*\([0-9][0-9]*\)[ 	]*/\1/'`
  
            # Determine the logical volume's permissions.
            lvdisplay ${VG_NAME}/${LV_NAME} | grep -i permission | \
              grep -i write > /dev/null
            if [ $? -eq 0 ]
              then
                PERMISSION="rw"
              else
                PERMISSION="r"
            fi
  
            # Determine if bad block relocation is enabled for the logical
            # volume.
            lvdisplay ${VG_NAME}/${LV_NAME} | grep -i bad | \
              grep on > /dev/null
            if [ $? -eq 0 ]
              then
                # Bad block relocation enabled
                BAD_BLOCK="Y"
              else
                # Bad block relocation disabled
                BAD_BLOCK="N"
            fi
            
            # Determine the allocation policy of the logical volume.
            ALLOCATION=`lvdisplay ${VG_NAME}/${LV_NAME} | \
                         grep -i allocation | \
                         sed -e 's/Allocation[ 	]*//' \
                             -e 's/[ 	]*$//'`
  
            # Determine the status of the logical volume.
            STATUS=`lvdisplay ${VG_NAME}/${LV_NAME} | grep -i status | \
                     sed -e 's/LV Status[ 	]*//' \
                         -e 's/[ 	]*$//'`
  

            # Determine the number of mirror copies of the logical volume.
            MIRROR=`lvdisplay ${VG_NAME}/${LV_NAME} | \
                 grep -i 'Mirror copies' | sed -e 's/^[^0-9]*\([0-9]\).*/\1/'`
  
            # Determine the mirror consistency recovery mode of the logical
            # volume.
            CONS_REC=`lvdisplay ${VG_NAME}/${LV_NAME} | \
                       grep -i "consistency recovery" | \
                       sed -e 's/Consistency Recovery[ 	]*//' \
                           -e 's/\([A-Z][A-Z]*\).*/\1/'`
  
            # Determine the scheduling policy of the logical volume.
            lvdisplay ${VG_NAME}/${LV_NAME} | grep -i schedule | \
              grep -i parallel > /dev/null
            if [ $? -eq 0 ]
              then
                # Parallel scheduling policy
                SCHEDULE="P"
              else 
                # Sequential scheduling policy
                SCHEDULE="S"
            fi

            # Display the logical volume's information.
	    if [ `echo ${LV_NAME} | wc -c` -le 16 ]
	      then
                # Print all information on one line.
                echo ${LV_NAME} ${LV_SIZE} ${PERMISSION} ${BAD_BLOCK} | \
                  awk '{ printf "   %15s  %5d %2s %1s", $1, $2, $3, $4 }'
                echo ${ALLOCATION} ${STATUS} ${MIRROR} ${CONS_REC} ${SCHEDULE} | \
		  awk '{ printf " %21s %15s %1s %5s %1s\n", $1, $2, $3, $4, $5 }'
	      else
		# If the logical volume name is longer than 15 characters,
		# print it on a seperate line.
                echo ${LV_NAME} | awk '{printf "   %s\n", $1}'
                echo ${LV_SIZE} ${PERMISSION} ${BAD_BLOCK} | \
                  awk '{ printf "                    %5d %2s %1s", $1, $2, $3}'
                echo ${ALLOCATION} ${STATUS} ${MIRROR} ${CONS_REC} ${SCHEDULE} | \
		  awk '{ printf " %21s %15s %1s %5s %1s\n", $1, $2, $3, $4, $5 }'
	    fi

          done

        echo
        echo "     (PERM) Access Permissions  (BB) Bad Block Relocation Policy  (#) Number"
        echo "    of Mirrors  (CR) Consistency Recovery Mode  (S) Scheduling of Disk Writes"

      done

  }




f_PhysicalVolumes()
  {

    ###########################################################################
    # Part 5:  The Physical Volumes on Your System
    #          -----------------------------------
    #          Physical volumes (or LVM disks) are disks that have been 
    #          initialized by LVM for use in a volume group.  The 
    #          f_PhysicalVolumes() function gives an overview of the physical
    #          volumes configured on the system and lists for each the
    #          following characteristics:
    #
    #            + Physical volume disk space usage:
    #              total, allocated, and free disk space; physical extent size
    #
    #            + Distribution of the physical volume:
    #              which logical volumes have disk space allocated on the 
    #              physical volume and how much.
    ###########################################################################
    

    echo
    echo
    echo ${SEPARATOR}
    echo
    echo "*************************"
    echo "Part 5:  PHYSICAL VOLUMES"
    echo "*************************"
    
    
    # Determine the physical volume names.
    PV_NAMES=`vgdisplay -v | grep -i 'pv name' | 
               sed -e 's/.*\(\/.*\/.*\/.*\)/\1/' | sort -u -k 1,1`

    for PV_NAME in ${PV_NAMES}
        do
          echo 
          echo 
          echo "Physical Volume: ${PV_NAME}"
          echo "****************"
    
          # Get disk space information for the physical volume.
          PE_SIZE=`pvdisplay -v ${PV_NAME} | grep 'PE Size' | \
                      sed -e 's/^[^0-9]*\([0-9][0-9]*\)[ 	]*/\1/'`
          TOTAL_PE=`pvdisplay -v ${PV_NAME} | grep 'Total PE' | \
                      sed -e 's/^[^0-9]*\([0-9][0-9]*\)[ 	]*/\1/'`
          ALLOC_PE=`pvdisplay -v ${PV_NAME} | grep 'Allocated PE' | \
                      sed -e 's/^[^0-9]*\([0-9][0-9]*\)[ 	]*/\1/'`
          FREE_PE=`pvdisplay -v ${PV_NAME} | grep 'Free PE' | \
                      sed -e 's/^[^0-9]*\([0-9][0-9]*\)[ 	]*/\1/'`
    
          echo
          echo "   Physical volume disk space usage:"
          echo
    
          echo `expr ${TOTAL_PE} \* ${PE_SIZE}` ${TOTAL_PE} | \
            awk '{printf "   Total    : %5d Mbytes  %5d PE\n", $1, $2}'
          echo `expr ${ALLOC_PE} \* ${PE_SIZE}` ${ALLOC_PE} | \
            awk '{printf "   Allocated: %5d Mbytes  %5d PE\n", $1, $2}'
          echo `expr ${FREE_PE} \* ${PE_SIZE}` ${FREE_PE} | \
            awk '{printf "   Free     : %5d Mbytes  %5d PE\n", $1, $2}'
          echo
          echo ${PE_SIZE} | \
            awk '{printf "   PE size  : %5d Mbytes\n", $1}'
          echo

          # List the logical volumes that have extents allocated in the
          # physical volume.
          echo "   Distribution of physical volume:"
          echo
          pvdisplay -v ${PV_NAME} | grep 'LE of LV'
          pvdisplay -v ${PV_NAME} | sed -n -e '/^   \//p'
        done

  }




f_FS_SW()
  {

    ###########################################################################
    # Part 6:  File Systems and Swap Space on Your System
    #          ------------------------------------------
    #          The f_FS_SW() function gives an overview of the file systems
    #          and swap space configured in the system.  With this information
    #          you can determine what the different logical volumes (and hard
    #          sections) are being used for. 
    #
    #          Unfortunately, there is no way to determine which logical 
    #          volumes (and/or hard sections) are being used for raw I/O or 
    #          those that have currently unmounted file systems.  The same is 
    #          true for non-activated swap space.  You will have to be 
    #          familiar with the operations on the system in order to determine
    #          what these are being used for (if anything at all).
    #
    #          No HP-UX commands can explicitely list logical volumes and/or
    #          disk sections that contain raw data.  Therefor, you might need
    #          to devise a means to keep track of logical volumes and/or disk
    #          sections used for raw data.  For example, when you create a 
    #          logical volume containing raw data, use the '-n' option to the
    #          lvcreate(1M) command to give your logical volume an easily
    #          recognizable name, such as /dev/vg00/lab_data, so that you can
    #          identify them later on.  Information about which logical volumes
    #          and/or sections that contain raw data, can also be put in the
    #          /etc/checklist file.
    #
    #          The following information is displayed:
    #
    #            + Mounted file systems:
    #              file system, total, used, and available space, percentage
    #              used, mount point
    #
    #            + Activated swap space
    ###########################################################################
    

    echo
    echo
    echo ${SEPARATOR}
    echo 
    echo "************************************"
    echo "Part 6:  FILE SYSTEMS AND SWAP SPACE"
    echo "************************************"

    
    # There is no way to determine which logical volumes are being used for raw
    # I/O and those that have currently unmounted file systems.  You will have
    # to be familiar with the operations on the system in order to determine
    # what these are being used for (if anything at all).  The same problem 
    # exists for non-LVM disks.
    #
    # Information about these logical volumes and/or disk sections can be put
    # as a comment in the '/etc/checklist' file.  When creating a logical 
    # volume to contain raw data, give the logical volume an easily 
    # recognizable name.

    # Print a warning message.

    cat <<EOF


WARNING  Logical volumes and/or disk sections that are being used for raw I/O,
         that contain inactivated swap space, or that have currently unmounted
         file systems are not indicated here.  You will have to be familiar 
         with the operations on the system to determine what these are being 
         used for (if anything at all).
EOF
    
    
    # Display a list of logical volumes and/or disk sections containing
    # currently mounted file systems.
    echo
    echo
    echo "Mounted file systems"
    echo "********************"
    echo
    bdf | sed -e 's/^/   /'
    

    # Display a list of the currently activated swap space.
    echo
    echo
    echo "Activated swap space"
    echo "********************"
    echo
    swapinfo -m | sed -e 's/^/   /'

  }




f_KernelConfiguration()
  {
    
    ###########################################################################
    #  Part 7:  Root / Primary Swap / Dumps / Kernel Configuration
    #           --------------------------------------------------
    #           The f_KernelConfiguration() function gives more information
    #           about the LVM related parts of the kernel configuration and
    #           about which logical volumes have been defined as root, primary
    #           swap, and as dump devices.  The kernel configuration 
    #           information is not retrieved from the /etc/conf/gen/S800 file,
    #           but from the running kernel.  For this we assume that the
    #           system has been booted from /hp-ux.
    #           
    #           The following information is displayed:
    #
    #             + Logical volume manager definitions for root, primary swap,
    #               and dumps: gives information about which logical volumes
    #               are used for the root file systen, for primary swap, and 
    #               that are configured as dump devices.  This information is
    #               stored in data structures on the bootable physical volumes
    #               and maintained using the lvlnboot(1M) and lvrmboot(1M)
    #               commands.  Also an overview of the physical volumes 
    #               belonging to the root volume group is given, and whether
    #               or not they can be used a boot disk.
    #
    #             + Kernel configuration for root, primary swap and dumps:
    #               gives the definitions for the kernel devices root, swap,
    #               and dumps.  Normally you would expect to see the following
    #               information:
    #                             root on lvol;
    #                             swap on lvol;
    #                             dumps on lvol;
    # 
    #             + LVM related system parameters:
    #               gives an overview of the tunable LVM system parameters.
    #               The values of the following system parameters are 
    #               retrieved:
    #                           maxvgs
    #
    #               When a system parameter has its default value, this is
    #               indicated.
    ###########################################################################
    

    echo
    echo
    echo ${SEPARATOR}
    echo 
    echo "***********************************************************"
    echo "Part 7:  ROOT / PRIMARY SWAP / DUMPS / KERNEL CONFIGURATION" 
    echo "***********************************************************"
    

    echo
    echo
    echo "Logical volume manager definitions for root, primary swap, and dumps"
    echo "********************************************************************"
    echo
    lvlnboot -v 2>&1 | sed -e 's/^/   /'


    echo
    echo
    echo "Kernel configuration for root, primary swap and dumps"
    echo "*****************************************************"
    echo
    get_kgenfile /hp-ux | grep root | sed -e 's/^/   /'
    get_kgenfile /hp-ux | grep swap | grep on | sed -e 's/^/   /'
      # avoid retrieving the maxswapchunks line
    get_kgenfile /hp-ux | grep dumps | sed -e 's/^/   /'
    
    
    echo
    echo
    echo "LVM related system parameters"
    echo "*****************************"
    echo
    MAXVGS=`echo 'maxvgs/D' | adb /hp-ux /dev/kmem | tail -1 | awk '{print $2}'`
    echo "Max number of volume groups (maxvgs) = ${MAXVGS}\c"

    if [ ${MAXVGS} -eq 10 ]
      then
        echo "    (default value)"
      else
        echo
    fi

  }




f_DeviceFiles()
  {
    
    ###########################################################################
    # Part 8:  LVM Device Files
    #          ----------------
    #          The f_DeviceFiles() function gives a listing of the LVM device 
    #          files for each volume group that is recognized on the system.
    #
    #          The major number is alway 64.
    #      
    #          The minor number of the device file contains the following 
    #          information:
    #
    #            0x##00##
    #              --  --
    #               |   |_ hexadecimal logical volume number (1..255)
    #               |      (00 is reserved for the group file)
    #               |_____ hexadecimal volume group number (0..255)
    #
    #          You need this information to recreate the device files if they
    #          were removed by mistake.
    ###########################################################################


    echo
    echo
    echo ${SEPARATOR}
    echo
    echo "*************************"
    echo "Part 8:  LVM DEVICE FILES"
    echo "*************************"


    # List all LVM related device files.

    # Determine the volume group names.
    VG_NAMES=`vgdisplay | grep 'VG Name' | sed -e 's/VG Name[ 	]*//'`
    
    # Retrieve device file information for each volume group.
    for VG_NAME in ${VG_NAMES}
      do
        echo
        echo
        echo "Volume Group: ${VG_NAME}"
        echo "*************"
        echo
    
        # List all device files in the volume group, sorted according to the
        # minor number.
        ll ${VG_NAME} | sed -e '1d' | sort +5 -6
    
      done

  }




f_Other()
  {

    ###########################################################################
    # Part 9:  Other
    #          -----
    #          The f_Other() function gives information about topics that were
    #          not included in the preceding functions.  The following 
    #          information is retrieved:
    #     
    #            + Volume group configuration backups:
    #              for each of the volume groups there is a check if the 
    #              /etc/lvmconf/<vg_name>.conf file exists.  If it doesn't,
    #              we assume that no volume group configuration backup was 
    #              made for this volume group, and the user is given a warning.
    #              We test here for the name of the default backup file 
    #              (another filename can be specified with the '-f' option of
    #              the vgcfgbackup(1M) command), so the procedure is not full
    #              proof.  Also there is no check if the backup is up to date.
    # 
    #            + Product desciption file check:
    #              a complete check of the LVM filesets is performed based on
    #              the respective product description files.  The following
    #              filesets are checked:
    #                                     LVM
    #                                     LVM-MIRROR
    #                                     LVM-MAN
    #
    #              Using this procedure we can easily see what has changed to
    #              the LVM related files (permissions, ownership, version, ...)
    #              and if they are still there.  The output of the product
    #              description file check can contribute to troubleshooting
    #              LVM related problems.
    ###########################################################################
    
    
    echo
    echo ${SEPARATOR}
    echo
    echo "**************"
    echo "Part 9:  OTHER"
    echo "**************"


    # Determine the volume group names.
    VG_NAMES=`vgdisplay | grep 'VG Name' | sed -e 's/VG Name[ 	]*//'`

    echo
    echo
    echo "Volume group configuration backups"
    echo "**********************************"
    echo

    # For each volume group determine if there is a backup of the volume 
    # group configuration.
    for VG_NAME in ${VG_NAMES}
      do
        if [ -f /etc/lvmconf/`basename ${VG_NAME}`.conf ]
	  then
	    ll /etc/lvmconf/`basename ${VG_NAME}`.conf
          else

            BACKUP_FILE=`basename ${VG_NAME}`
cat <<EOF

WARNING:  The volume group configuration backup was not found at the default 
          location '/etc/lvmconf/${BACKUP_FILE}.conf'.  

EOF

	fi
      done


    echo
    echo
    echo "Product description file check"
    echo "******************************"
    echo
    
    # NOTE:  If the optional product MirrorDisk/UX is installed on the system,
    #        checking the product description file for fileset LVM will give the
    #        following error messages:
    #
    #          /etc/lvcreate: checksum(2159831298 -> 22134964)
    #          /etc/lvextend: checksum(922995795 -> 695297870)
    #          /etc/lvreduce: checksum(1897612301 -> 147029433)
    #
    #        These commands were replaced in order to add LVM-mirroring options.
    #        Both the versions off each command can be found under the 
    #        /etc/newconfig directory.  Patch installation will also affect the
    #        output of the pdfck(1M) command.
    
    for FILESET in LVM LVM-MIRROR LVM-MAN
      do 
        echo "Fileset: ${FILESET}"
        echo
    
        if [ -f /system/${FILESET}/pdf ]
          then
            # The product description file exists
            pdfck /system/${FILESET}/pdf > ${TEMPFILE}
    
            if [ -s ${TEMPFILE} ]
              then
                cat ${TEMPFILE} | sed -e 's/^/   /'
              else
                echo "   ok"
            fi
    
            rm -f ${TEMPFILE}
          else
            echo "   Could not find the product description file '/system/${FILESET}/pdf'."
        fi
    
        echo
      done
    echo

  }


###############################################################################
###############################################################################
#
# Script main body.
#
###############################################################################
###############################################################################


# Initialize shell variables.

FULL_SCRIPT_NAME=$0
TEMPFILE="/tmp/${SCRIPT_NAME}.$$"
SEPARATOR="..............................................................................."
SEPARATOR2="*******************************************************************************"


# Provide cleanup of temporary file when interrupted.
trap "echo '\n\nInterrupted, cleaning up.\n'; rm -f ${TEMPFILE} > /dev/null 2>&1; exit 4" 1 2 15


# Determine if Logical Volume Manager is installed.

if [ ! -f "/etc/filesets/LVM" ]
  then
    echo
    echo "${SCRIPT_NAME}: no LVM software installed on this system !"
    echo
    exit 2
fi


# Determine if the /etc/lvmtab file is present on the system.

# The file /etc/lvmtab contains information about how physical volumes are
# grouped on your system (which volume groups contain which disks).  Many
# LVM commands rely on /etc/lvmtab, so it is important not to rename it or
# destroy it.

if [ ! -f /etc/lvmtab ]
  then
    echo
    echo "The /etc/lvmtab file is not present on the system.  Load the file"
    echo "from backup or try to rebuild it using the vgscan(1M) command."
    echo
    exit 3
fi


    # Run all parts of the script.

    f_Header

    f_Index
    f_SystemConf
    f_VolumeGroups
    f_PhysicalVolumeGroups
    f_LogicalVolumes
    f_PhysicalVolumes
    f_FS_SW
    f_KernelConfiguration
    f_DeviceFiles
    f_Other 
    echo ${SEPARATOR}


#  If we make it to here, the script should have executed alright.

rm -rf ${TEMPFILE} > /dev/null 2>&1

}

lvmcollect_10()
{

###############################################################################
###############################################################################
#
# Function definitions.
#
###############################################################################
###############################################################################




f_Header()
{

    # Display an header giving additional information and warnings.
    #
    # The script revision number and run time are displayed.  The user is
    # warned that all the physical volumes should be on-line to create an
    # accurate picture of the Logical Volume Manager system configuration.


    echo "${SEPARATOR2}"
    echo "*******                                                                 *******"
    echo "*******        LOGICAL VOLUME MANAGER (LVM) SYSTEM CONFIGURATION        *******"
    echo "*******                                                                 *******"
    echo "*******                                                                 *******"
    echo "*******                                                                 *******"
    echo "${SEPARATOR2}"

    date

    # Display warning message.
    echo "\n\nWARNING:  All the physical volumes should be on-line while scanning"
    echo "          the Logical Volume Manager (LVM) system configuration."

}




f_Index()
{

    # Display the index to show what information will be retrieved.


    echo "\n\n${SEPARATOR}\n"
    echo "*****"
    echo "INDEX"
    echo "*****\n\n"

    echo "Part 1:  SYSTEM CONFIGURATION"
    echo "Part 2:  VOLUME GROUPS"
    echo "Part 3:  PHYSICAL VOLUME GROUPS"
    echo "Part 4:  LOGICAL VOLUMES"
    echo "Part 5:  PHYSICAL VOLUMES"
    echo "Part 6:  FILE SYSTEMS AND SWAP SPACE"
    echo "Part 7:  ROOT / PRIMARY SWAP / DUMPS / KERNEL CONFIGURATION"
    echo "Part 8:  LVM DEVICE FILES"
    echo "Part 9:  OTHER"

}



f_SystemConf()
{

    ###########################################################################
    # Part 1:  Your System's Hardware
    #          ----------------------
    #          The f_SystemConf() function will help you gather information
    #          about the disks and other hardware on your system pertaining
    #          to LVM.
    #
    #          It retrieves the following information:
    #
    #            + System an operating system:
    #              system name, machine hardware model name, machine
    #              identification number, operating system release, license
    #              level, amount of memory
    #
    #            + Disks configured:
    #              disk type, disk capacity, interface type, hardware address,
    #              device name, physical volumes, bootable physical volumes
    #
    #            + LVM mirroring software
    #              whether the optional MirrorDisk/UX product is installed
    ###########################################################################


    echo "\n\n${SEPARATOR}\n"
    echo "*****************************"
    echo "Part 1:  SYSTEM CONFIGURATION"
    echo "*****************************"


    # Identify the system type, operating system release and license level.

    SYSTEM_NAME=`uname -n`
    HW_MODEL=`uname -m`
    MACHINE_ID=`uname -i`
    OS_REL=`uname -r`
    LICENSE_LEVEL=`uname -l`
    VERSION_LEVEL=`uname -v`

    echo "\n\nSystem and operating system"
    echo     "***************************\n"
    echo "   System name                  : ${SYSTEM_NAME}"
    echo "   Machine hardware model name  : ${HW_MODEL}"
    echo "   Machine identification number: ${MACHINE_ID}"
    echo "   Operating system release     : ${OS_REL}"
    echo "   License level                : ${LICENSE_LEVEL} (${VERSION_LEVEL})"


    # Determine the memory size.

    # Real memory expressed in units of pages (4 kbytes per page).
    REAL_MEM=`echo 'physmem/D'| adb /stand/vmunix /dev/kmem | tail -1 | \
              awk '{print $2}'`
    echo "   Real memory                  : `expr ${REAL_MEM} / 256` Mbytes"


    # Identify the hardware address and interface type for each disk on the
    # system.

    echo "\n\nDisks configured"
    echo     "****************\n"

    echo "     I  H/W Path   Driver      S/W State   Description"
    echo "   ===================================================================="

    ioscan -fC disk | sed -e '1,2d' | \
    while line=`line`
    do
        set -- $(echo $line);

        I=$2
        HW_PATH=$3
        DRIVER=$4
        SW_STATE=$5
        HW_TYPE=$6
        shift; shift; shift; shift; shift; shift;
        DESCRIPTION=$*

        echo ${I} ${HW_PATH} ${DRIVER} ${SW_STATE} | \
        awk '{printf "   %3d  %9s  %-10s  %-10s  ", $1, $2, $3, $4}'
        echo ${DESCRIPTION}

    done

    echo


    # Get additional information for each disk: product id, size, (bootable)
    # physical volume.
    echo "   Device     H/W Path   Product id    Size     Physical      Alternate"
    echo "                                       (Mbytes) Volume        Link     "
    echo "   ===================================================================="

    # NOTE:  A CD-ROM drive may NOT answer nicely to diskinfo if there is no
    #        CD present.  Depending on the type of CD-ROM
    #        drive, the diskinfo(1M) command returns an error that the
    #        device cannot be opened.  For example, when using the diskinfo(1M)
    #        command on a XM-3301TA CD-ROM drive with no CD inserted, it will
    #        return the following error message: "diskinfo: can't open
    #        /dev/dsk/c#d#t#: No such device or address" (return code 1).

    # Retrieve more information about the disks: product id, size, physical
    # volumes, bootable physical volumes.

    ioscan -fC disk | sed -e '1,2d' | \
    while line=`line`
    do
        set -- $(echo $line); HW_PATH=$3
        set -- $(ioscan -fnC disk -H ${HW_PATH} | sed -e '1,3d')
        DEVNAME=`basename $1`


        # Determine if the disk is a PV
        pvdisplay /dev/dsk/${DEVNAME} 2>&1 | \
            grep -i pvdisplay > /dev/null 2>&1

        if [ $? -ne 0 ]
        then

            # The disk is a physical volume
            PV="yes"

            # Check if the physical volume is bootable.  A physical volume
            # is assumed to be bootable if it contains a LIF area, and the
            # LIF area contains the initial system loader (ISL).  This is not
            # full proof, but it will give a good indication in the normal
            # cases.  For more information about the LIF area, see the verbose
            # output of LVMcollect.

            lifls /dev/dsk/${DEVNAME} 2> /dev/null | \
                grep -i isl > /dev/null 2>&1

            if [ $? -eq 0 ]
            then
                # Bootable PV
                BOOTABLE_PV="bootable"
            else
                # Non-bootable PV
                BOOTABLE_PV=""
            fi

            # Determine if this is a physical volume link
            pvdisplay /dev/dsk/${DEVNAME} | grep -i 'Using Primary Link' > /dev/null
            if [ $? -eq 0 ]
            then
                PV_Link="yes"
            else
                PV_Link="no"
            fi

        else

            # The disk is not recognized as a physical volume.
            PV="no"
            BOOTABLE_PV=""
            PV_Link="n/a"

        fi


        # Filter out the hard disks, no information needs to be displayed for
        # other disk devices like CD-ROM's and cartridge tapes.

        # Cartridge tape drives and CD-ROM's may not respond nicely
        # to the diskinfo(1M) command !
        diskinfo /dev/rdsk/${DEVNAME} > ${TEMPFILE} 2> /dev/null
        if [ $? -eq 0 ]
        then

            set -- $(cat ${TEMPFILE} | sed -e '/product id/!d'); PRODUCT_ID=$3
            set -- $(cat ${TEMPFILE} | sed -e '/size/!d'); SIZE=$2

            # Product id does not return nice for CD-ROM, spaces !  Print out
            # separated so that only the first part of the product id is
            # printed.

            echo ${DEVNAME} ${HW_PATH} ${PRODUCT_ID} `expr ${SIZE} / 1024` ${PV} | \
                awk '{printf "   %9s  %9s  %-12s  %6d   %-3s ", $1, $2, $3, $4, $5}'

            if [ "${BOOTABLE_PV}" != "" ]
            then
                echo ${BOOTABLE_PV} ${PV_Link} | awk '{printf "%8s  %-3s\n", $1, $2}'
            else
                echo ${PV_Link} | awk '{printf "          %-3s\n", $1}'
            fi

         else

            echo ${DEVNAME} | awk '{printf "   %9s  >> Error: Device is not a hard disk or is unavailable. <<\n", $1}'

        fi

        rm -f ${TEMPFILE}

    done

    echo "\n   Note:  All disk devices are listed here, not only hard disks."


    # Determine if the optional LVM mirroring software is installed.

    echo
    echo
    echo "LVM mirroring software"
    echo "**********************"
    echo

    if [ -f "/sbin/lvsync" ]
    then
        MIRROR="yes"
        echo "   LVM mirroring software MirrorDisk/UX (B2491A) is installed."
    else
        MIRROR="no"
        echo "   LVM mirroring software MirrorDisk/UX (B2491A) is NOT installed."
    fi

}




f_VolumeGroups()
{

    ###########################################################################
    # Part 2:  The Volume Groups on Your System
    #          --------------------------------
    #          The f_VolumeGroups() function will help you identify the volume
    #          groups on your system, and for each volume group:
    #
    #            + The physical volumes associated with the volume group.
    #
    #            + The volume group capacity: total, allocated, and free disk
    #              space expressed in Mbytes and in physical extents.
    #
    #            + The volume group's physical extent size.
    ###########################################################################


    echo "\n\n${SEPARATOR}\n"
    echo "**********************"
    echo "Part 2:  VOLUME GROUPS"
    echo "**********************"


    # Identify the volume groups and physical volumes.

    # Retrieve more information about each volume group: physical volumes, disk
    # space usage, physical extent size.
    vgdisplay | grep 'VG Name' | sed -e 's/VG Name[   ]*//' | \
    while read VG_NAME
    do
        echo "\n\nVolume Group: ${VG_NAME}"
        echo     "*************\n"

        # List all physical volumes in the volume group.

        echo "   Physical Volumes:"
        echo
        vgdisplay -v ${VG_NAME} | grep -i name | grep -iv lv | \
            grep -iv pvg | sed -e 1d | sed -e 's/.*\(\/.*\/.*\/.*\)/\1/' | \
            sort -u -k 1,1 | sed -e 's/^/   /'
        echo

        # Get disk space information for the volume group.

        PE_SIZE=`vgdisplay ${VG_NAME} | grep 'PE Size' | \
                  sed -e 's/^[^0-9]*\([0-9][0-9]*\)[    ]*/\1/'`
        TOTAL_PE=`vgdisplay ${VG_NAME} | grep 'Total PE' | \
                   sed -e 's/^[^0-9]*\([0-9][0-9]*\)[   ]*/\1/'`
        ALLOC_PE=`vgdisplay ${VG_NAME} | grep 'Alloc PE' | \
                   sed -e 's/^[^0-9]*\([0-9][0-9]*\)[   ]*/\1/'`
        FREE_PE=`vgdisplay ${VG_NAME} | grep 'Free PE' | \
                   sed -e 's/^[^0-9]*\([0-9][0-9]*\)[   ]*/\1/'`

        echo "   Volume group disk space usage:"
        echo
        echo `expr ${TOTAL_PE} \* ${PE_SIZE}` ${TOTAL_PE} | \
            awk '{printf "   Total    : %5d Mbytes  %5d PE\n", $1, $2}'
        echo `expr ${ALLOC_PE} \* ${PE_SIZE}` ${ALLOC_PE} | \
            awk '{printf "   Allocated: %5d Mbytes  %5d PE\n", $1, $2}'
        echo `expr ${FREE_PE} \* ${PE_SIZE}` ${FREE_PE} | \
            awk '{printf "   Free     : %5d Mbytes  %5d PE\n\n", $1, $2}'
        echo ${PE_SIZE} | \
            awk '{printf "   PE size  : %5d Mbytes\n", $1}'
      done
}




f_PhysicalVolumeGroups()
{

    ###########################################################################
    # Part 3:  The Physical Volume Groups on Your System
    #          -----------------------------------------
    #          Physical volume groups are subgroups of LVM disks (physical
    #          volumes) within a volume group.  An ASCII file, /etc/lvmpvg
    #          contains all the mapping information for the physical volume
    #          group, but the mapping is not recorded on the disk.
    #
    #          This part of the procedure will help you identify:
    #
    #            + For each volume group, the physical volume groups.
    #
    #            + For each physical volume group, the physical volumes.
    ###########################################################################


    echo "\n\n${SEPARATOR}\n"
    echo "*******************************"
    echo "Part 3:  PHYSICAL VOLUME GROUPS"
    echo "*******************************"


    if [ -f /etc/lvmpvg ]
    then
        # For each volume group, show the physical volumes defined.

        # NOTE:  The existance of the /etc/lvmpvg file doesn't imply that
        #        there are physical volume groups defined for each volume
        #        group.  Catch the abscence and display an appropriate message.

        vgdisplay | grep 'VG Name' | sed -e 's/VG Name[       ]*//' | \
        while read VG_NAME
        do
            echo "\n\nVolume Group: ${VG_NAME}"
            echo     "*************\n"

            rm -f ${TEMPFILE} > /dev/null 2>&1
            vgdisplay -v ${VG_NAME} | \
                sed -n -e '/Physical volume groups/,$p' | \
                tee ${TEMPFILE} | \
                sed -e '1d' \
                    -e '$d' \
                    -e '$d' \
                    -e 's/.*PVG Name[     ]*/   Physical volume group: /' \
                    -e 's/.*PV Name[      ]*/   /'

            # The existance of the '/etc/lvmpvg' file doesn't imply that there
            # are physical volume groups defined for each volume group.  Catch
            # the abscence and display an appropriate message.

            if [ ! -s ${TEMPFILE} ]
            then
                echo "No physical volume groups were defined for this volume group."
            fi
        done

    else

        # The '/etc/lvmpvg' file is missing.
        echo "\n\nNo physical volume groups were defined, see lvmpvg(4)."

    fi


}




f_LogicalVolumes()
{

    ###########################################################################
    # Part 4:  The Logical Volumes on Your System
    #          ----------------------------------
    #          In part 2 of the procedure you identified the volume groups that
    #          are defined on your system.  These are pools of disk space from
    #          which logical volumes (the LVM equivalent of disk sections) are
    #          created.
    #
    #          The f_LogicalVolumes() function will help you identify:
    #          the logical volumes on your system, which volume groups they are
    #          part of, how big they are, the logical volume permissions, bad
    #          block allocation policy, allocation policy, status, whether they
    #          are mirrored (single, or double) or not mirrored at all,
    #          consistency recovery, scheduling policy, and information about
    #          disk striping: number of disks in the stripe, stripe size.
    #
    #          Arguments passed:
    #            $2  Can be the name of a valid volume group.  In this case
    #                limit the output of f_LogicalVolumes() to only that
    #                volume group.  This argument can only be passed when the
    #                -p4 option is used.
    #                An invalid argument is ignored.
    ###########################################################################


    echo "\n\n${SEPARATOR}\n"
    echo "************************"
    echo "Part 4:  LOGICAL VOLUMES"
    echo "************************"


    VG=$2

    if [ "${VG}" != "" ]
    then
        # Check if volume exists, else ignore argument
        vgdisplay ${VG}> /dev/null 2>&1
        if [ $? -eq 0 ]
        then
            echo "\n\nWarning:  Output limited to volume group ${VG}."
        else
            echo "f_LogicalVolumes(): Volume group '${VG}' does not exist, ignoring argument." >> ${LOGFILE}
            VG=""
        fi
    fi


    vgdisplay ${VG} | grep 'VG Name' | sed -e 's/VG Name[   ]*//' | \
    while read VG_NAME
    do
        echo "\n\nVolume Group: ${VG_NAME}"
        echo "*************\n"

        echo "   Logical Volume  Size   PE B  Alloc. Status          Mirroring   Stripes"
        echo "   Name            Mbytes RM B                         #   CR  S     # Size"
        echo "   ========================================================================"

        # Retrieve more information for each logical volume.
        vgdisplay -v ${VG_NAME} | grep -i 'lv name' | sed -e 's/.*\/.*\/.*\/\(.*\)/\1/' | \
        while read LV_NAME
        do
            # Determine the logical volume's size.
            set -- $(lvdisplay ${VG_NAME}/${LV_NAME} | sed -e '/LV Size.*[0-9][0-9]*/!d'); LV_SIZE=$4

            # Determine the logical volume's permissions.
            lvdisplay ${VG_NAME}/${LV_NAME} | grep -i "LV Permission" | \
                grep -i write > /dev/null
            if [ $? -eq 0 ]
            then
                PERMISSION="rw"
            else
                PERMISSION="r"
            fi

            # Determine if bad block relocation is enabled for the logical
            # volume.
            lvdisplay ${VG_NAME}/${LV_NAME} | grep -i "Bad block" | \
                grep on > /dev/null
            if [ $? -eq 0 ]
            then
                # Bad block relocation enabled
                BAD_BLOCK="Y"
            else
                # Bad block relocation disabled
                BAD_BLOCK="N"
            fi

            # Determine the allocation policy of the logical volume.
            set -- $(lvdisplay ${VG_NAME}/${LV_NAME} | sed -e '/Allocation/!d' \
                       -e 's/contiguous/C/'  -e 's/strict/S/'); ALLOCATION=$2

            # Determine the status of the logical volume.
            set -- $(lvdisplay ${VG_NAME}/${LV_NAME} | sed -e '/LV Status/!d'); STATUS=$3


            # Determine the number of mirror copies of the logical volume.
            set -- $(lvdisplay ${VG_NAME}/${LV_NAME} | sed -e '/Mirror copies/!d'); MIRROR=$3

            # Determine the mirror consistency recovery mode of the logical
            # volume.
            set -- $(lvdisplay ${VG_NAME}/${LV_NAME} | sed -e '/Consistency Recovery/!d'); CONS_REC=$3

            # Determine the scheduling policy of the logical volume.
            set -- $(lvdisplay ${VG_NAME}/${LV_NAME} | sed -e '/Schedule/!d' \
                       -e 's/parallel/par/' -e 's/sequential/seq/' \
                       -e 's/striped/str/'); SCHEDULE=$2

            # Determine the number of disk striped accross.
            set -- $(lvdisplay ${VG_NAME}/${LV_NAME} | sed -e '/Stripes/!d'); STRIPES=$2

            # Determine the stripe size (in Kbytes)
            set -- $(lvdisplay ${VG_NAME}/${LV_NAME} | sed -e '/Stripe Size/!d'); STRIPE_SIZE=$4

            # Display the logical volume's information.
            if [ `echo ${LV_NAME} | wc -c` -le 16 ]
            then
                # Print all information on one line.
                echo ${LV_NAME} ${LV_SIZE} ${PERMISSION} ${BAD_BLOCK} | \
                    awk '{ printf "   %15s  %5d %2s %1s", $1, $2, $3, $4 }'
                echo ${ALLOCATION} ${STATUS} ${MIRROR} ${CONS_REC} ${SCHEDULE} | \
                    awk '{ printf " %7s %15s %1s %5s %3s", $1, $2, $3, $4, $5 }'
                echo ${STRIPES} ${STRIPE_SIZE} | \
                    awk '{ printf " %3d %4d\n", $1, $2}'
            else
                # If the logical volume name is longer than 15 characters,
                # print it on a seperate line.
                echo ${LV_NAME} | awk '{printf "   %s\n", $1}'
                echo ${LV_SIZE} ${PERMISSION} ${BAD_BLOCK} | \
                    awk '{ printf "                    %5d %2s %1s", $1, $2, $3}'
                echo ${ALLOCATION} ${STATUS} ${MIRROR} ${CONS_REC} ${SCHEDULE} | \
                    awk '{ printf " %7s %15s %1s %5s %1s", $1, $2, $3, $4, $5 }'
                echo ${STRIPES} ${STRIPE_SIZE} | \
                    awk '{ printf " %3d %4d\n", $1, $2}'
            fi

        done

#        echo
#        echo "     (PERM) Access Permissions  (BB) Bad Block Relocation Policy  (#) Number"
#        echo "    of Mirrors  (CR) Consistency Recovery Mode  (S) Scheduling of Disk Writes"
#
        cat <<EOF

   (PERM) Access Permissions;  (BB) Bad Block Relocation Policy;  Mirroring:
   (#) Number of Mirrors  (CR) Consistency Recovery Mode  (S) Scheduling of
   Disk Writes;  Stripes: (#) Number of Disk Stripes  (Size) Size in kbytes
EOF

    done

}




f_PhysicalVolumes()
{

    ###########################################################################
    # Part 5:  The Physical Volumes on Your System
    #          -----------------------------------
    #          Physical volumes (or LVM disks) are disks that have been
    #          initialized by LVM for use in a volume group.  The
    #          f_PhysicalVolumes() function gives an overview of the physical
    #          volumes configured on the system and lists for each the
    #          following characteristics:
    #
    #            + Physical volume disk space usage:
    #              total, allocated, and free disk space; physical extent size
    #
    #            + Distribution of the physical volume:
    #              which logical volumes have disk space allocated on the
    #              physical volume and how much.
    ###########################################################################


    echo "\n\n${SEPARATOR}\n"
    echo "*************************"
    echo "Part 5:  PHYSICAL VOLUMES"
    echo "*************************"


    vgdisplay -v | grep -i 'pv name' | sed -e 's/.*\(\/.*\/.*\/.*\)/\1/' | sort -u -k 1,1 | \
    while read LINE
    do

        # Determine whether we are dealing with Physical Volume Links
        echo ${LINE} | grep 'Alternate Link' > /dev/null
        if [ $? -eq 0 ]
        then
            set -- $(echo ${LINE}); PV_NAME=$1
            ALTLINK="Alternate Link"
        else
            PV_NAME=${LINE}
            ALTLINK=""
        fi


        echo "\n\nPhysical Volume: ${PV_NAME}  ${ALTLINK}"
        echo     "****************"

        if [ "${ALTLINK}" != "" ]
        then

            # Display additional information about Alternate Link
            echo
            pvdisplay ${PV_NAME} | sed -n -e '1,2p' | sed -e 's/^/   /'

            cat <<EOF

   Refer to the corresponding Primary Link for information.  Note
   that the indicated device file for the primary link may not be
   the right one. Use a device file with the same value for 't<#>'.
EOF

        else

            # Get disk space information for the physical volume.
            set -- $(pvdisplay ${PV_NAME} | sed -e '/PE Size.*[0-9][0-9]*/!d'); PE_SIZE=$4
            set -- $(pvdisplay ${PV_NAME} | sed -e '/Total PE.*[0-9][0-9]*/!d'); TOTAL_PE=$3
            set -- $(pvdisplay ${PV_NAME} | sed -e '/Allocated PE.*[0-9][0-9]*/!d'); ALLOC_PE=$3
            set -- $(pvdisplay ${PV_NAME} | sed -e '/Free PE.*[0-9][0-9]*/!d'); FREE_PE=$3

            pvdisplay ${PV_NAME} | grep -i 'alternate link' > /dev/null
            if [ $? -eq 0 ]
            then
                echo "\n   *** Alternate Link available ***"
            fi

            echo
            echo "   Physical volume disk space usage:"
            echo

            echo `expr ${TOTAL_PE} \* ${PE_SIZE}` ${TOTAL_PE} | \
                awk '{printf "   Total    : %5d Mbytes  %5d PE\n", $1, $2}'
            echo `expr ${ALLOC_PE} \* ${PE_SIZE}` ${ALLOC_PE} | \
                awk '{printf "   Allocated: %5d Mbytes  %5d PE\n", $1, $2}'
            echo `expr ${FREE_PE} \* ${PE_SIZE}` ${FREE_PE} | \
                awk '{printf "   Free     : %5d Mbytes  %5d PE\n", $1, $2}'
            echo ${PE_SIZE} | \
                awk '{printf "   PE size  : %5d Mbytes\n", $1}'
            echo

            # List the logical volumes that have extents allocated in the
            # physical volume.
            echo "   Distribution of physical volume:"
            echo
            pvdisplay -v ${PV_NAME} | grep 'LE of LV'
            pvdisplay -v ${PV_NAME} | sed -n -e '/^   \//p'

        fi

    done

}




f_FS_SW()
{

    ###########################################################################
    # Part 6:  File Systems and Swap Space on Your System
    #          ------------------------------------------
    #          The f_FS_SW() function gives an overview of the file systems
    #          and swap space configured in the system.  With this information
    #          you can determine what the different logical volumes (and hard
    #          sections) are being used for.
    #
    #          Unfortunately, there is no way to determine which logical
    #          volumes (and/or hard sections) are being used for raw I/O or
    #          those that have currently unmounted file systems.  The same is
    #          true for non-activated swap space.  You will have to be
    #          familiar with the operations on the system in order to determine
    #          what these are being used for (if anything at all).
    #
    #          No HP-UX commands can explicitely list logical volumes and/or
    #          disk sections that contain raw data.  Therefore, you might need
    #          to devise a means to keep track of logical volumes and/or disk
    #          sections used for raw data.  For example, when you create a
    #          logical volume containing raw data, use the '-n' option to the
    #          lvcreate(1M) command to give your logical volume an easily
    #          recognizable name, such as /dev/vg00/lab_data, so that you can
    #          identify them later on.  Information about which logical volumes
    #          and/or sections that contain raw data, can also be put in the
    #          /etc/fstab file.
    #
    #          The following information is displayed:
    #
    #            + Mounted file systems:
    #              file system, total, used, and available space, percentage
    #              used, mount point
    #
    #            + Activated swap space
    ###########################################################################


    echo "\n\n${SEPARATOR}\n"
    echo "************************************"
    echo "Part 6:  FILE SYSTEMS AND SWAP SPACE"
    echo "************************************"


    # There is no way to determine which logical volumes are being used for raw
    # I/O and those that have currently unmounted file systems.  You will have
    # to be familiar with the operations on the system in order to determine
    # what these are being used for (if anything at all).  The same problem
    # exists for non-LVM disks.
    #
    # Information about these logical volumes and/or disk sections can be put
    # as a comment in the '/etc/fstab' file.  When creating a logical
    # volume to contain raw data, give the logical volume an easily
    # recognizable name.

    # Print a warning message.

    cat <<EOF


WARNING  Logical volumes and/or disk sections that are being used for raw I/O,
         that contain inactivated swap space, or that have currently unmounted
         file systems are not indicated here.  You will have to be familiar
         with the operations on the system to determine what these are being
         used for (if anything at all).
EOF


    # Display a list of logical volumes and/or disk sections containing
    # currently mounted file systems.
    echo "\n\nMounted file systems"
    echo     "********************\n"

    echo "   Type   Filesystem          kbytes    used   avail %used Mounted on"
    bdf | sed -e '1d' -e 's/[   ].*//' | grep '/dev/' | \
    while read DEVNAME
    do

        # grep '/dev/' is needed as bdf can output multiple lines for
        # one file system if the device name is long

        FSTYP=`fstyp ${DEVNAME}`
        echo ${FSTYP} | \
        awk '{printf "   %-7s", $1}'
        echo "`bdf ${DEVNAME} | sed -e '1d'`"

    done


    # Display a list of the currently activated swap space.
    echo "\n\nActivated swap space"
    echo     "********************\n"
    swapinfo -m | sed -e 's/^/   /'

}




f_KernelConfiguration()
{

    ###########################################################################
    #  Part 7:  Root / Primary Swap / Dumps / Kernel Configuration
    #           --------------------------------------------------
    #           The f_KernelConfiguration() function gives more information
    #           about the LVM related parts of the kernel configuration and
    #           about which logical volumes have been defined as root, primary
    #           swap, and as dump devices.  The kernel configuration
    #           information is not retrieved from the /stand/system file,
    #           but from the running kernel.  For this we assume that the
    #           system has been booted from /stand/vmunix.
    #
    #           The following information is displayed:
    #
    #             + Logical volume manager definitions for root, primary swap,
    #               and dumps: gives information about which logical volumes
    #               are used for the root file systen, for primary swap, and
    #               that are configured as dump devices.  This information is
    #               stored in data structures on the bootable physical volumes
    #               and maintained using the lvlnboot(1M) and lvrmboot(1M)
    #               commands.  Also an overview of the physical volumes
    #               belonging to the root volume group is given, and whether
    #               or not they can be used as a boot disk.
    #
    #             + Kernel configuration for root, primary swap and dumps:
    #               gives the definitions for the kernel devices root, swap,
    #               and dumps.  Normally you would expect to see the following
    #               information:
    #                             swap lvol
    #                             dumps lvol
    #
    #             + LVM related system parameters:
    #               gives an overview of the tunable LVM system parameters.
    #               The value of the following system parameter is retrieved:
    #
    #                           maxvgs
    #
    ###########################################################################


    echo "\n\n${SEPARATOR}\n"
    echo "***********************************************************"
    echo "Part 7:  ROOT / PRIMARY SWAP / DUMPS / KERNEL CONFIGURATION"
    echo "***********************************************************"


    echo "\n\nLogical volume manager definitions for root, primary swap, and dumps"
    echo     "********************************************************************\n"
    lvlnboot -v 2>&1 | sed -e 's/^/   /'


    echo "\n\nKernel configuration for primary swap and dump"
    echo     "**********************************************\n"
    echo "*system_data/s" | adb /stand/vmunix /dev/kmem | grep swap | grep -v maxswapchunks
    echo "*system_data/s" | adb /stand/vmunix /dev/kmem | grep dump


    echo "\n\nLVM related system parameters"
    echo     "*****************************\n"

    set -- $(echo 'maxvgs/D' | adb /stand/vmunix /dev/kmem | sed -e '/maxvgs:.*[0-9][0-9]*/!d')
    MAXVGS=$2
    echo "Maximum number of volume groups (maxvgs) = ${MAXVGS}\c"

    if [ ${MAXVGS} -eq 10 ]
    then
        echo "    (default value)"
    else
        echo
    fi

}




f_DeviceFiles()
{

    ###########################################################################
    # Part 8:  LVM Device Files
    #          ----------------
    #          The f_DeviceFiles() function gives a listing of the LVM device
    #          files for each volume group that is recognized on the system.
    #
    #          The major number is alway 64.
    #
    #          The minor number of the device file contains the following
    #          information:
    #
    #            0x##00##
    #              --  --
    #               |   |_ hexadecimal logical volume number (1..255)
    #               |      (00 is reserved for the group file)
    #               |_____ hexadecimal volume group number (0..255)
    #
    #          You need this information to recreate the device files if they
    #          were removed by mistake.
    ###########################################################################


    echo "\n\n${SEPARATOR}\n"
    echo "*************************"
    echo "Part 8:  LVM DEVICE FILES"
    echo "*************************"


    # List all LVM related device files.

    vgdisplay | grep 'VG Name' | sed -e 's/VG Name[  ]*//' | \
    while read VG_NAME
    do
        echo "\n\nVolume Group: ${VG_NAME}"
        echo "*************\n"

        # List all device files in the volume group, sorted according to the
        # minor number.
        ll ${VG_NAME} | sed -e '1d' | sort +5 -6

    done

}




f_Other()
{

    ###########################################################################
    # Part 9:  Other
    #          -----
    #          The f_Other() function gives information about topics that were
    #          not included in the preceding functions.  The following
    #          information is retrieved:
    #
    #            + Volume group configuration backups:
    #              for each of the volume groups there is a check if the
    #              /etc/lvmconf/<vg_name>.conf file exists.  If it doesn't,
    #              we assume that no volume group configuration backup was
    #              made for this volume group, and the user is given a warning.
    #              We test here for the name of the default backup file
    #              (another filename can be specified with the '-f' option of
    #              the vgcfgbackup(1M) command), so the procedure is not full
    #              proof.  Also there is no check if the backup is up to date.
    #
    #            + Version information is displayed for the commands
    #              vgcfgbackup(1M) and vgcfgrestore(1M), both for the verions
    #              under /sbin and /usr/sbin.
    ###########################################################################


    echo "\n\n${SEPARATOR}\n"
    echo "**************"
    echo "Part 9:  OTHER"
    echo "**************"


    echo "\n\nVolume group configuration backups"
    echo     "**********************************\n"

    # For each volume group determine if there is a backup of the volume
    # group configuration.
    vgdisplay | grep 'VG Name' | sed -e 's/VG Name[     ]*//' | \
    while read VG_NAME
    do
        if [ -f /etc/lvmconf/`basename ${VG_NAME}`.conf ]
        then
            ll /etc/lvmconf/`basename ${VG_NAME}`.conf
        else

            BACKUP_FILE=`basename ${VG_NAME}`
cat <<EOF

WARNING:  The volume group configuration backup was not found at the default
          location '/etc/lvmconf/${BACKUP_FILE}.conf'.

EOF
        fi
    done


    echo "\n\nvgcfgbackup(1M) and vgcfgrestore(1M) command versions"
    echo     "*****************************************************\n"

    what /sbin/vgcfgbackup | sed -e 's/^/   /'
    echo
    what /usr/sbin/vgcfgbackup | sed -e 's/^/   /'
    echo
    what /sbin/vgcfgrestore | sed -e 's/^/   /'
    echo
    what /usr/sbin/vgcfgrestore | sed -e 's/^/   /'
    echo "\n\n"

}



###############################################################################
###############################################################################
#
# Script main body.
#
###############################################################################
###############################################################################


# Initialize shell variables.

FULL_SCRIPT_NAME=$0
TEMPFILE="/tmp/${SCRIPT_NAME}.$$"
LOGFILE="/dev/null"
SEPARATOR="..............................................................................."
SEPARATOR2="*******************************************************************************"


# Check the operating system release.

uname -a | grep '10.' > /dev/null
if [ $? -ne 0 ]
then
    echo "\nThis version of LVMcollect is for HP-UX release 10.\n"
    exit 1
fi


# Provide cleanup of temporary file when interrupted.
trap "echo '\n\nInterrupted, cleaning up.\n'; rm -f ${TEMPFILE} > /dev/null 2>&1;echo '======= ' `date '+%d/%m/%y %X %z'` ' Interrupted\n' >> ${LOGFILE}; exit 1" 1 2 15


# Determine if Logical Volume Manager is installed.

if [ ! -f "/sbin/vgcfgbackup" ]
then
    echo "\n${SCRIPT_NAME}: LVM software not installed.\n"
    exit 1
fi


# Determine if the /etc/lvmtab file is present on the system.

# The file /etc/lvmtab contains information about how physical volumes are
# grouped on your system (which volume groups contain which disks).  Many
# LVM commands rely on /etc/lvmtab, so it is important not to rename it or
# destroy it.

if [ ! -f /etc/lvmtab ]
then
    echo "\nThe /etc/lvmtab file is not present on the system.  Load the file"
    echo   "from backup or try to rebuild it using the vgscan(1M) command.\n"
    exit 1
fi


    # Run all parts of the script.

    f_Header

    f_Index
    f_SystemConf
    f_VolumeGroups
    f_PhysicalVolumeGroups
    f_LogicalVolumes
    f_PhysicalVolumes
    f_FS_SW
    f_KernelConfiguration
    f_DeviceFiles
    f_Other
    echo ${SEPARATOR}


#  If we make it to here, the script should have executed alright.

rm -rf ${TEMPFILE} > /dev/null 2>&1

}

lvm_info()
{
if [ $OS_VERSION -lt 10 ]
then
        lvmcollect_9
else
        lvmcollect_10
fi
}

attach_header()
{
if [ $MAIL_FILE="YES" ]
then
mail_header
fi
}


mail_report()
{
if [ $MAIL_FILE="YES" ]
then

   if [[ $CUST_EMAIL != "" ]]
      then
      mail $CUST_EMAIL < $OUTPUT_FILE
   fi

   if [[ $ALT_EMAIL != "" ]]
      then
      mail $ASE_EMAIL  < $OUTPUT_FILE
   fi
fi
}

disk_firmware()
{
date_variable=$(date)
hostname_variable=$(hostname)
uname_rev=$(uname -r)
uname_model=$(uname -m)
serial_no="0000A00000"


########################## SEPERATE ROWS FUNCTION ########################## 
seperator()
{

print "======================================================================="
}



######################## HEADER FOR DISK OUTPUT FUNCTION ################
banner_disk()
{


print "|DISK#|DISK VENDOR|  DISK ID  |   DISK ADDRESS   | DISK REV |"

}



########################## DISKINFO FUNCTION ##############################
get_diskinfo()
{


typeset -L11 _hostname_variable=$hostname_variable
typeset -L12  _uname_model=$uname_model
typeset -L10  _uname_rev=$uname_rev

typeset -i disk_num=1
typeset -L13 disk_vendor
typeset -L12 disk_id
typeset -L19 DISK
typeset -L10 disk_re


for DISK in $(ls /dev/rdsk/c*)
do

	typeset -L3 disk_num
	print -n "$disk_num   "

	disk_vendor=$(diskinfo -v $DISK | grep "vendor" | awk '{print $2}') 
        if [ -n $disk_vendor ]
        then
        {}
        else
        disk_vendor="NoResponse"
        fi

	print -n "$disk_vendor"

	disk_id=$(diskinfo -v $DISK | grep "product id" | awk '{print $3}')
        if [ -n $disk_id ]
        then
        {}
        else
        disk_id="N/A"
        fi
	print -n "$disk_id"

	print -n "$DISK"

	disk_rev=$(diskinfo -v $DISK | grep "rev level" | awk '{print $3}')
	print "$disk_rev"

	typeset -i disk_num
	disk_num=disk_num+1


done

}
banner_disk
seperator
get_diskinfo
}


##########################################################################
##########################################################################
#                              MAIN PROGRAM                              #
##########################################################################

check_user
get_opts $*
mail_report

#
#  EOF
#
