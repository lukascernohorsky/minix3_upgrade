#!/bin/sh
echo "grep -n \"Error code\" nbsd-upgrade.log.build | head -20"
grep -n "Error code" nbsd-upgrade.log.build | head -20

echo "grep -n \"error:\" nbsd-upgrade.log.build | head -40"
grep -n "error:" nbsd-upgrade.log.build | head -40

echo "tail -50 nbsd-upgrade.log.build"
tail -50 nbsd-upgrade.log.build
