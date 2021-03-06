#   -*-makefile-*-
#   library-combo.make
#
#   Determine which runtime, foundation and gui library to use.
#
#   Copyright (C) 1997, 2001 Free Software Foundation, Inc.
#
#   Author:  Scott Christley <scottc@net-community.com>
#   Author:  Nicola Pero <n.pero@mi.flashnet.it>
#
#   This file is part of the GNUstep Makefile Package.
#
#   This library is free software; you can redistribute it and/or
#   modify it under the terms of the GNU General Public License
#   as published by the Free Software Foundation; either version 3
#   of the License, or (at your option) any later version.
#   
#   You should have received a copy of the GNU General Public
#   License along with this library; see the file COPYING.
#   If not, write to the Free Software Foundation,
#   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

# Get library_combo from LIBRARY_COMBO or default_library_combo (or
# from the command line if the user defined it on the command line by
# invoking `make library_combo=gnu-gnu-gnu'; command line
# automatically takes the precedence over makefile definitions, so
# setting library_combo here has no effect if the user already defined
# it on the command line).
ifdef LIBRARY_COMBO
  library_combo := $(LIBRARY_COMBO)
else
  library_combo := $(default_library_combo)
endif

# Handle abbreviations for library combinations.
the_library_combo = $(library_combo)

ifeq ($(the_library_combo), nx)
  the_library_combo = nx-nx-nx
endif

ifeq ($(the_library_combo), apple)
  the_library_combo = apple-apple-apple
endif

ifeq ($(the_library_combo), gnu)
  the_library_combo = gnu-gnu-gnu
endif

ifeq ($(the_library_combo), ng)
  the_library_combo = ng-gnu-gnu
endif

ifeq ($(the_library_combo), fd)
  the_library_combo = gnu-fd-gnu
endif

# Strip out the individual libraries from the library_combo string
combo_list = $(subst -, ,$(the_library_combo))

# NB: The user can always specify any of the OBJC_RUNTIME_LIB, the
# FOUNDATION_LIB and the GUI_LIB variable manually overriding our
# determination.

ifeq ($(OBJC_RUNTIME_LIB),)
  OBJC_RUNTIME_LIB = $(word 1,$(combo_list))
endif

ifeq ($(FOUNDATION_LIB),)
  FOUNDATION_LIB = $(word 2,$(combo_list))
endif

ifeq ($(GUI_LIB),)
  GUI_LIB = $(word 3,$(combo_list))
endif

# Now build and export the final LIBRARY_COMBO variable, which is the
# only variable (together with OBJC_RUNTIME_LIB, FOUNDATION_LIB and
# GUI_LIB) the other makefiles need to know about.  This LIBRARY_COMBO
# might be different from the original one, because we might have
# replaced it with a library_combo provided on the command line, or we
# might have fixed up parts of it in accordance to some custom
# OBJC_RUNTIME_LIB, FOUNDATION_LIB and/or GUI_LIB !
export LIBRARY_COMBO = $(OBJC_RUNTIME_LIB)-$(FOUNDATION_LIB)-$(GUI_LIB)

OBJC_LDFLAGS =
OBJC_LIBS = 

#
# Set the appropriate ObjC runtime library and other information
#
# PS: OBJC_LIB_FLAG is set by config.make.
ifeq ($(OBJC_RUNTIME_LIB), gnu)
  OBJC_LDFLAGS =
  OBJC_LIB_DIR =
  OBJC_LIBS = $(OBJC_LIB_FLAG)
  RUNTIME_FLAG   = -fgnu-runtime
  RUNTIME_DEFINE = -DGNU_RUNTIME=1
endif

ifeq ($(OBJC_RUNTIME_LIB), ng)
  OBJC_LDFLAGS =
  OBJC_LIB_DIR =
  OBJC_LIBS = $(OBJC_LIB_FLAG) -fobjc-nonfragile-abi
  RUNTIME_FLAG = -fobjc-runtime=gnustep-1.8 -fblocks
  RUNTIME_DEFINE = -DGNUSTEP_RUNTIME=1 -D_NONFRAGILE_ABI=1
  # Projects may control the use of ARC by defining GS_WITH_ARC=1
  # or GS_WITH_ARC=0 at the start of their GNUmakefile, or in the environment,
  # or as an argument to the 'make' command.
  # The default behavior is not to use ARC, unless GNUSTEP_NG_ARC is
  # set to 1 (perhaps in the GNUstep config file; GNUstep.conf).
  #
  ifeq ($(GS_WITH_ARC),)
    ifeq ($(GNUSTEP_NG_ARC), 1)
      GS_WITH_ARC=1
    endif
  endif
  ifeq ($(GS_WITH_ARC), 1)
    RUNTIME_FLAG += -fobjc-arc
    RUNTIME_DEFINE += -DGS_WITH_ARC=1
  endif
endif

ifeq ($(OBJC_RUNTIME_LIB), nx)
  RUNTIME_FLAG = -fnext-runtime
  RUNTIME_DEFINE = -DNeXT_RUNTIME=1
  ifeq ($(FOUNDATION_LIB), gnu)
    OBJC_LIBS = $(OBJC_LIB_FLAG)
  endif
endif

ifeq ($(OBJC_RUNTIME_LIB), sun)
  RUNTIME_DEFINE = -DSun_RUNTIME=1
endif

ifeq ($(OBJC_RUNTIME_LIB), apple)
  RUNTIME_FLAG = -fnext-runtime
  RUNTIME_DEFINE = -DNeXT_RUNTIME=1
  OBJC_LIBS = $(OBJC_LIB_FLAG)
endif

FND_LDFLAGS =
FND_LIBS =
#
# Set the appropriate Foundation library
#
ifeq ($(FOUNDATION_LIB), gnu)
  FOUNDATION_LIBRARY_NAME   = gnustep-base
  FOUNDATION_LIBRARY_DEFINE = -DGNUSTEP_BASE_LIBRARY=1
endif

#
# Third-party foundations not using make package
# Our own foundation will install a base.make file into 
# $GNUSTEP_MAKEFILES/Additional/ to set the needed flags
#
ifeq ($(FOUNDATION_LIB), nx)
  # -framework Foundation is used both to find headers, and to link
  INTERNAL_OBJCFLAGS += -framework Foundation
  FND_LIBS   = -framework Foundation
  FND_DEFINE = -DNeXT_Foundation_LIBRARY=1
  LIBRARIES_DEPEND_UPON += -framework Foundation
  BUNDLE_LIBS += -framework Foundation
endif

ifeq ($(FOUNDATION_LIB), sun)
  FND_DEFINE = -DSun_Foundation_LIBRARY=1
endif

ifeq ($(FOUNDATION_LIB), apple)
  # -framework Foundation is used only to link
  FND_LIBS   = -framework Foundation
  FND_DEFINE = -DNeXT_Foundation_LIBRARY=1
  LIBRARIES_DEPEND_UPON += -framework Foundation
endif

#
# FIXME - Ask Helge to move this inside his libFoundation, and have 
# it installed as a $(GNUSTEP_MAKEFILES)/Additional/libFoundation.make
#
ifeq ($(FOUNDATION_LIB), fd)
  -include $(GNUSTEP_MAKEFILES)/libFoundation.make

  FND_DEFINE = -DLIB_FOUNDATION_LIBRARY=1
  FND_LIBS = -lFoundation

  ifeq ($(gc), yes)
    ifeq ($(LIBFOUNDATION_WITH_GC), yes)
      ifeq ($(leak), yes)
        AUXILIARY_CPPFLAGS += -DLIB_FOUNDATION_LEAK_GC=1
      else
        AUXILIARY_CPPFLAGS += -DLIB_FOUNDATION_BOEHM_GC=1
      endif
    endif
  endif

endif

GUI_LDFLAGS =
GUI_LIBS = 
#
# Third-party GUI libraries - our own sets its flags into 
# $(GNUSTEP_MAKEFILES)/Additional/gui.make
#
ifeq ($(GUI_LIB), nx)
  GUI_DEFINE = -DNeXT_GUI_LIBRARY=1
  # -framework AppKit is used both to find headers, and to link
  INTERNAL_OBJCFLAGS += -framework AppKit
  GUI_LIBS = -framework AppKit
  LIBRARIES_DEPEND_UPON += -framework AppKit
  BUNDLE_LIBS += -framework AppKit
endif

ifeq ($(GUI_LIB), apple)
  GUI_DEFINE = -DNeXT_GUI_LIBRARY=1
  # -framework AppKit is used only to link
  GUI_LIBS = -framework AppKit
  LIBRARIES_DEPEND_UPON += -framework AppKit
endif

SYSTEM_INCLUDES = $(CONFIG_SYSTEM_INCL)
SYSTEM_LDFLAGS = $(LDFLAGS)
SYSTEM_LIB_DIR = $(CONFIG_SYSTEM_LIB_DIR)
SYSTEM_LIBS =
