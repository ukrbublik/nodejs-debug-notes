#!/bin/bash

########################### parse cmd args

for option
do
  case $option in

  -help | --help | -h)
    _WANT_HELP="YES" ;;

  -logs-dir=* | --logs-dir=*)
    _LOGS_DIR=`expr "x$option" : "x-*logs-dir=\(.*\)"`
    ;;

  -pfind=* | --pfind=*)
    _PROC_FIND=`expr "x$option" : "x-*pfind=\(.*\)"`
    ;;

  -pid=* | --pid=*)
    _PID=`expr "x$option" : "x-*pid=\(.*\)"`
    ;;

  -*)
    {
      echo "ERROR: unrecognized option: $option"
      echo "Try \`$0 --help' for more information." >&2
      { exit 1; }
    }
    ;; 

  esac
done

########################### process cmd args

if [ -z "$_PROC_FIND" ] && [ -z "$_PID" ]; then
  echo "None of --pid or --pfind is specified"
  exit 1
fi

if [ -z "$_PID" ]; then
    _PIDS=`ps aux | grep "$_PROC_FIND" | grep -v "grep" | grep -v "$0" | grep -v "sh -c $_PROC_FIND" | awk '{print $2}'`
    if [ -z "$_PIDS" ]; then
        echo "No process found by $_PROC_FIND"
        exit 1
    fi
    _PIDS_ARR=($_PIDS)
    if ! [ -z "${_PIDS_ARR[1]}" ]; then
        echo "More than one process found by $_PROC_FIND"
        echo $_PIDS
        exit 1
    fi
    _PID=${_PIDS_ARR[0]}
fi

if ! [ -d $_LOGS_DIR ]; then
  mkdir -p $_LOGS_DIR
  chmod 777 $_LOGS_DIR
fi

########################### show help

if test "x$_WANT_HELP" = xYES; then
  cat <<EOF
Terminate nodejs infinite loop or other blocking code.
GDB should be installed.
You should have root priviliges.

Usage: $0 {--pid=PID or --pfind=PFIND} [--logs-dir=<path>]

Configuration:
  -h, --help                Display this help and exit
  --pid=PID                 PID of taget nodejs app
  --pfind=PFIND             Cmd string of taget nodejs app to automatically find its PID
  --logs-dir=PATH           Path for stacktrace logs.
                            If not specified, stack trace will be printed to nodejs app output

EOF
fi
test -n "$_WANT_HELP" && exit 0

########################### run gdb

if [ -z "$_LOGS_DIR" ]; then
    gdb -p $_PID \
        -batch \
        -ex "b v8::internal::Runtime_StackGuard" \
        -ex "p 'v8::Isolate::GetCurrent'()" \
        -ex "p 'v8::Isolate::TerminateExecution'(\$1)" \
        -ex "c" \
        -ex "p 'v8::internal::Runtime_DebugTrace'(0, 0, (void *)(\$1))" \
        -ex "detach" \
        -ex "quit"
    echo "==========="
    echo "Stack trace has been printed to nodejs app output"
else
    NOW=`date +%Y_%m_%d__%H_%M_%S`
    TRACE_FILENAME="$NOW.txt"
    TRACE_PATH="$_LOGS_DIR/$TRACE_FILENAME"
    TRACE_FULLPATH=`realpath "$TRACE_PATH"`
    #touch "$TRACE_FULLPATH"
    # $1 - GetCurrent, $2 - stdout_copy, $3 - fd of log
    gdb -p $_PID \
        -batch \
        -ex "handle SIGPIPE nostop noprint pass" \
        -ex "b v8::internal::Runtime_StackGuard" \
        -ex "p 'v8::Isolate::GetCurrent'()" \
        -ex "p dup(1)" \
        -ex "p open(\"$TRACE_FULLPATH\", 66, 0777)" \
        -ex "p 'v8::Isolate::TerminateExecution'(\$1)" \
        -ex "c" \
        -ex "p dup2(\$3, 1)" \
        -ex "p 'v8::internal::Runtime_DebugTrace'(0, 0, (void *)(\$1))" \
        -ex "p dup2(\$2, 1)" \
        -ex "p close(\$2)" \
        -ex "p close(\$3)" \
        -ex "detach" \
        -ex "quit"
    echo "==========="
    echo "Stack trace has been saved to $TRACE_FULLPATH"
fi

###########################
