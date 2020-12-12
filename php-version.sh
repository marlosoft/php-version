#!/usr/bin/env sh

declare -a php_versions

version=$(php -v | grep -o -e "PHP [0-9+]\.[0-9+]" | cut -d " " -f2)
php_versions=($(brew ls --versions | egrep "^php(\ |@)" | cut -d " " -f2 | grep -o -e "[0-9+]\.[0-9+]" | xargs))

if [ -z "$1" ]; then
  php_versions=$(printf ", %s" "${php_versions[@]}")

  echo "Usage: $(basename $0) <version>"
  echo "PHP Versions: ${php_versions:2}"
  exit 0
fi

version_found=0
for php_version in ${php_versions[@]}; do
  if [ "${php_version}" = "$1" ]; then
    version_found=1
    break
  fi
done

if [ ${version_found} = 0 ]; then
  echo "Specified PHP version $1 is not installed."
  exit 1
fi

if [ "${version}" = "$1" ]; then
  echo "Cannot change PHP to the same version."
  exit 1
fi

apache_conf_file=$(apachectl -V | grep "SERVER_CONFIG_FILE" | cut -d '"' -f 2)
php_module=$(cat ${apache_conf_file} | grep -e "^LoadModule" | grep "libphp")
new_php_module=$(brew info "php@$1" | grep "LoadModule" | grep "libphp" | xargs)

sed -i "" "s#${php_module}#${new_php_module}#g" ${apache_conf_file}
brew unlink php
brew link "php@$1" --force --overwrite
brew services restart httpd

cp "${apache_conf_file}" "${apache_conf_file}.bak"
