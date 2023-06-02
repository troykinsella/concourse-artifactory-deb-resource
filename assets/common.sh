
attr() {
  local type=$1
  local name=$2
  local val=$(jq -r ".$type.$name // \"\"" < $payload)
  test -z "$val" && { echo "Must supply '$name' $type attribute" >&2; exit 1; }
  echo $val
}

trusted_flag() {
  local trusted=$(jq -r '.source.trusted // ""' < $payload)
  if [ "$trusted" = "true" ] || [ "$trusted" = "yes" ]; then
    echo "[trusted=yes]"
  fi
}

deb_source() {
  local repository=$(attr source repository)
  local distribution=$(attr source distribution)
  local component=$(jq -r '.source.component // "main"' < $payload)
  echo "deb $(trusted_flag) $repository $distribution $component"
}

deb_sources() {
  deb_source
  local other_sources=$(jq -r '.source.other_sources // []' < $payload)
  IFS=$'\n'
  for s in $(echo "$other_sources" | jq -r '.[]'); do
    echo $s
  done
  unset IFS
}

add_keys() {
  local apt_keys=$(jq -r '.source.apt_keys // []' < $payload)
  IFS=$'\n'
  for k in $(echo "$apt_keys" | jq -r '.[]'); do
    echo "Installing apt key: $k"
    curl -fSsL -o "/etc/apt/trusted.gpg.d/$(echo "$k" | md5sum).asc" "$k"
  done
  unset IFS
}
