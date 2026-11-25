#pragma once

#include <cstring>
#include <esp_log.h>
#include <esp_ota_ops.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <nvs.h>

inline bool levoit_matter_data_present() {
  nvs_handle_t handle;
  if (nvs_open("levoit", NVS_READONLY, &handle) != ESP_OK)
    return false;
  nvs_close(handle);
  return true;
}

inline void erase_other_firmware_task(void *) {
  const esp_partition_t *running = esp_ota_get_running_partition();
  esp_ota_img_states_t state = ESP_OTA_IMG_PENDING_VERIFY;
  for (int waited = 0; waited < 600; waited += 5) {
    if (esp_ota_get_state_partition(running, &state) != ESP_OK || state != ESP_OTA_IMG_PENDING_VERIFY)
      break;
    vTaskDelay(pdMS_TO_TICKS(5000));
  }
  const esp_partition_t *other = esp_ota_get_next_update_partition(nullptr);
  esp_app_desc_t mine, theirs;
  if (state != ESP_OTA_IMG_PENDING_VERIFY && other != nullptr &&
      esp_ota_get_partition_description(running, &mine) == ESP_OK &&
      esp_ota_get_partition_description(other, &theirs) == ESP_OK &&
      strncmp(mine.project_name, theirs.project_name, sizeof(mine.project_name)) != 0) {
    ESP_LOGW("dual", "erasing %s from %s", theirs.project_name, other->label);
    esp_partition_erase_range(other, 0, other->size);
  }
  vTaskDelete(nullptr);
}

inline void erase_other_firmware() {
  xTaskCreate(erase_other_firmware_task, "erase_other", 3072, nullptr, 1, nullptr);
}
