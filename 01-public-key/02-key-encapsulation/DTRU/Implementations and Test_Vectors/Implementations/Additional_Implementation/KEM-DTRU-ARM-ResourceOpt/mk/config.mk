# SPDX-License-Identifier: Apache-2.0 or CC0-1.0
CPPFLAGS += \
	-DPQM4 \
	$(if $(PROFILE_FUNCTIONS),-DPROFILE_FUNCTIONS)

PK_PACK_OPT ?= 0
CPPFLAGS += -DPK_PACK_OPT=$(PK_PACK_OPT)
HOST_CPPFLAGS += -DPK_PACK_OPT=$(PK_PACK_OPT)
RETAINED_VARS += PK_PACK_OPT

define PROJECT_VAR_CHECK
ifeq ($$(origin LAST_$(1)),undefined)
$$(info Variable $(1) added, forcing rebuild!)
.PHONY: $(CONFIG)
else
ifneq "$$($(1))" "$$(LAST_$(1))"
$$(info Variable $(1) changed, forcing rebuild!)
.PHONY: $(CONFIG)
endif
endif
endef

$(foreach VAR,PK_PACK_OPT,$(eval $(call PROJECT_VAR_CHECK,$(VAR))))
