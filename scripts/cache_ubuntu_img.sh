#!/bin/bash

IMAGE_FILE_NAME="base_image.img"

check_vars() {
  if [[ -z "${IMG_CACHE_DIR}" ]]; then
    printf "%s environment variable must exist" "${IMG_CACHE_DIR}"
    exit 1
  fi
  if [[ -z "${UBUNTU_IMG_URL}" ]]; then
    printf "%s environment variable must exist" "${UBUNTU_IMG_URL}"
    exit 1
  fi
  if [[ -z "${IMG_DISK_SIZE}" ]]; then
    printf "%s environment variable must exist" "${IMG_DISK_SIZE}"
    exit 1
  fi
  if ! command -v wget &>/dev/null; then
    printf "wget must exist on the host executing terraform in order to execute this module"
    exit 2
  fi
  if ! command -v qemu-img &>/dev/null; then
    printf "qemu-img must exist on the host executing terraform in order to execute this module"
    exit 2
  fi
}

check_image_cached() {
  if [[ -e "${IMG_CACHE_DIR}/${IMAGE_FILE_NAME}" ]]; then
    return 0
  fi
  return 1
}

download_image() {
  mkdir -p "${IMG_CACHE_DIR}" || return $?
  wget -qO "${IMG_CACHE_DIR}/${IMAGE_FILE_NAME}" "${UBUNTU_IMG_URL}"
  return $?
}

resize_image() {
  qemu-img resize "${IMG_CACHE_DIR}/${IMAGE_FILE_NAME}" "${IMG_DISK_SIZE}"
  return $?
}

cache_image() {
  check_vars
  if check_image_cached; then
    return 0
  fi
  if ! download_image; then
    printf "Couldn't download image: %s to %s" "${UBUNTU_IMG_URL}" "${IMG_CACHE_DIR}/${IMAGE_FILE_NAME}"
    exit 3
  fi
  if ! resize_image; then
    printf "Couldn't resize image: %s to %s" "${IMG_CACHE_DIR}/${IMAGE_FILE_NAME}" "${IMG_DISK_SIZE}"
    exit 4
  fi
}

cache_image
exit 0
