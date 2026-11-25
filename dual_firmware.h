#pragma once

#include <nvs.h>

inline bool levoit_matter_data_present() {
  nvs_handle_t handle;
  if (nvs_open("levoit", NVS_READONLY, &handle) != ESP_OK)
    return false;
  nvs_close(handle);
  return true;
}
