
attr() {
  local type=$1
  local name=$2
  local val=$(jq -r ".$type.$name // \"\"" < $payload)
  test -z "$val" && { echo "Must supply '$name' $type attribute"; exit 1; }
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
  local other_sources=$(jq -r '.source.other_sources // ""' < $payload)
  IFS=$'\n'
  for s in $(echo "$other_sources" | jq -r '.[]'); do
    echo $s
  done
  unset IFS
}

list_versions() {
  local package=$(attr source package)
  local filter="cat"
  local version_pattern=$(jq -r '.source.version_pattern // ""' < $payload)
  
  if [ -n "$version_pattern" ]; then
    filter="egrep ^${version_pattern}"
  fi
  apt-cache madison $package | awk '{print $3}' | $filter
}

latest_version() {
  list_versions | head -1
}
