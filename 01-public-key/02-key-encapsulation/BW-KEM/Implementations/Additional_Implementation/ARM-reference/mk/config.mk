# SPDX-License-Identifier: Apache-2.0 or CC0-1.0
CPPFLAGS += \
	-DPQM4 \
	$(if $(PROFILE_FUNCTIONS),-DPROFILE_FUNCTIONS)
