# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0


 
PWDD := $(shell pwd)
BLOCKS := $(shell basename $(PWDD))

# ---- Include Partitioned Makefiles ----

CONFIG = caravel_user_project

HEADER_FILES += \
SOURCE_FILES += \
SIM_DEFINES = -DDEBUG_FLASH -DDEBUG_CACHED_MEMORY

include $(MCW_ROOT)/verilog/dv/make/env.makefile
include $(TARGET_PATH)/verilog/dv/make/experiarSoC.makefile
include $(TARGET_PATH)/verilog/dv/make/user_sim.makefile


