## 
## -------------------------------------------------------------
##    Copyright 2010 Cadence.
##    All Rights Reserved Worldwide
## 
##    Licensed under the Apache License, Version 2.0 (the
##    "License"); you may not use this file except in
##    compliance with the License.  You may obtain a copy of
##    the License at
## 
##        http://www.apache.org/licenses/LICENSE-2.0
## 
##    Unless required by applicable law or agreed to in
##    writing, software distributed under the License is
##    distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
##    CONDITIONS OF ANY KIND, either express or implied.  See
##    the License for the specific language governing
##    permissions and limitations under the License.
## -------------------------------------------------------------
## 

x: all

#
# Include file for IUS Makefiles
#

UVM_VERBOSITY =	UVM_LOW

#
# Note that "-access rw" have an adverse impact on performance
# and should not be used unless necessary.
#
# They are used here because they are required by some examples
# (backdoor register accesses).
#


TEST = /usr/bin/test
N_ERRS = 0
N_FATALS = 0

XCELIUM =	xrun -access rw -uvmhome $(UVM_HOME) +UVM_VERBOSITY=$(UVM_VERBOSITY) -quiet -uvmnocdnsextra +access+rwc -linedebug -uvmlinedebug -input input.tcl


CHECK = \
	@$(TEST) \( `grep -c 'UVM_ERROR :    $(N_ERRS)' xrun.log` -eq 1 \) -a \
		 \( `grep -c 'UVM_FATAL :    $(N_FATALS)' xrun.log` -eq 1 \)

clean:
	rm -rf *~ core csrc simv* vc_hdrs.h ucli.key *.log *.shm xcelium.d xrun.history xrun.key
