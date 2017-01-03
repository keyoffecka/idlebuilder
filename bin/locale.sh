#!/bin/bash

#Should be executed mannually once after installing GLibC x86_64 for the base system.

set +h
set -e
set -u

mkdir -pv /usr/lib64/locale

/usr/bin/localedef -i ru_RU -f ISO-8859-5 ru_RU
/usr/bin/localedef -i ru_RU -f KOI8-R ru_RU
/usr/bin/localedef -i ru_RU -f CP1251 ru_RU
/usr/bin/localedef -i ru_RU -f IBM866 ru_RU
/usr/bin/localedef -i ru_RU -f UTF-8 ru_RU

/usr/bin/localedef -i en_US -f ISO-8859-1 en_US
/usr/bin/localedef -i en_US -f UTF-8 en_US

/usr/bin/localedef -i en_GB -f ISO-8859-1 en_GB
/usr/bin/localedef -i en_GB -f UTF-8 en_GB

/usr/bin/localedef -i es_ES -f ISO-8859-1 es_ES
/usr/bin/localedef -i es_ES -f UTF-8 es_ES

/usr/bin/localedef -i es_MX -f ISO-8859-1 es_MX
/usr/bin/localedef -i es_MX -f UTF-8 es_MX

/usr/bin/localedef -i fr_FR -f ISO-8859-1 fr_FR
/usr/bin/localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
/usr/bin/localedef -i fr_FR -f UTF-8 fr_FR

/usr/bin/localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
/usr/bin/localedef -i ja_JP -f EUC-JP ja_JP
