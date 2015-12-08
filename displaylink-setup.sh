#!/bin/sh

# --- info
#
# Original script developed by sipdude 2015-10-03
#
# The sleep calls are necessary to prevent the X server from crashing.
# Feel free to adjust as needed

# --- settings for DGM 1920X1080 AND F419 AUTO connected to 2 monitors
# D_CENTER connected to DP and D_LEFT and D_RIGHT to HDMI 
#
D_LAPTOP=eDP1
#D_LEFT=DVI-3-2
D_CENTER=DVI-2-1
D_RIGHT=DVI-1-0

# --- monitor mode and framerate
#
MODE_CENTER=1920x1080
MODE_RIGHT=1280x1024

# --- functions
#
handle_rc()
{
   local rc

   rc=$1 ; shift

   if [ $rc -eq 0 ] ; then
      echo " done!"
   else
      echo " fail!";
      exit $rc
   fi
}

visual_sleep()
{
   local esc pfx sec

   sec=$1 ; shift
   [ -n "$1" ] && pfx="$1" || pfx="Waiting: "

   esc="\033[2K\33[u" 

   echo -n "\33[s"

   while [ $sec -gt 0 ] ; do
      echo -n "$esc$pfx$sec"
      sec=$((sec - 1))
      sleep 1
   done

   echo -n "$esc"
}

# --- service
#
[ -n "$1" -a x"$1" = "xauto" ] && AUTO=Y || AUTO=N
[ -n "$DISPLAY" ] && X_DISPLAY=$DISPLAY || X_DISPLAY=":0"

[ "$AUTO" = "Y" ] && echo "Running in automatic mode" || echo "Running in interactive mode"
echo "Using X display: $X_DISPLAY"

echo -n "Checking displaylink service:"
if ! /bin/systemctl status displaylink.service | grep -q 'Active: active (running)' >/dev/null ; then
   echo " not started!"

   if [ "$AUTO" = "Y" ] ; then 
      echo "Cannot start the displaylink service in automatic mode. Aborting!"
      exit
   fi

   echo "Attempting to start service..."
   sudo /bin/systemctl start displaylink.service
   rc=$?

   if [ $rc -eq 0 ] ; then
       echo "Successfully started displaylink service."
   else
      echo "Failed to start displaylink service!"
      exit
   fi

   visual_sleep 3
else
   echo " already started!"

   echo "Attempting to restart service..."
   sudo /bin/systemctl restart displaylink.service
   rc=$?

   if [ $rc -eq 0 ] ; then
       echo "Successfully restarted displaylink service."
   else
      echo "Failed to restart displaylink service!"
      exit
   fi

   visual_sleep 3
fi

# --- inits
#
echo -n "Initializing outputs:"

for outp in 1 2 ; do
   echo -n " $outp";
   xrandr --setprovideroutputsource $outp 0
   rc=$?
   if [ $rc -eq 0 ] ; then echo -n ":ok" ; else echo ":fail"; exit $rc; fi
   sleep 1 
done

echo

# --- displays 
#
echo -n "Enabling display $D_CENTER:"
xrandr --display $X_DISPLAY --output $D_CENTER --mode $MODE_CENTER
handle_rc $?

echo -n "Enabling display $D_RIGHT:"
xrandr --display $X_DISPLAY --output $D_RIGHT --mode $MODE_RIGHT
handle_rc $?

visual_sleep 1

# --- positions 
#
echo -n "Setting position for center display:"
xrandr --display $X_DISPLAY --output $D_CENTER --right-of $D_LAPTOP --primary
handle_rc $?
visual_sleep 1

echo -n "Setting position for right display:"
xrandr --display $X_DISPLAY --output $D_RIGHT --right-of $D_CENTER
handle_rc $?
visual_sleep 1

# --- laptop
#
#echo -n "Turning off laptop display:"
#xrandr --display $X_DISPLAY --output $D_LAPTOP --off
#handle_rc $?
#visual_sleep 10

echo "Finished!"
exit 0
