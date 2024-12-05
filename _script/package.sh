#!/bin/bash
CWD=$(cd -P "$(dirname "$0")" && pwd)

bye() {
    echo "$1" >&2
    stat=($(</proc/$$/stat))
    [ ${stat[3]} -eq 1 ] && read # Pause if called in separate window
    exit 1
}

cd "$CWD"/.. || bye "Cannot go to parent directory"

AddonName=SOFIA

# Retrieve version and check consistency
VERSION_TOC_VERSION=$(grep -i '^##[[:space:]]*version:' ./$AddonName.toc | grep -o '[0-9].*')
VERSION_TOC_TITLE=$(grep -i '^##[[:space:]]*title:' ./$AddonName.toc | grep -o '|c........[0-9].*|r' | sed 's/|c........\([0-9].*\)|r/\1/')
VERSION_CHANGELOG=$(grep -m1 -o '^#### v[^[:space:]]*' ./changelog.md | grep -o '[0-9].*')
if [ -z "$VERSION_TOC_VERSION" ] || [[ "$VERSION_TOC_VERSION" =~ \n ]] \
|| [ -z "$VERSION_TOC_TITLE" ] || [[ "$VERSION_TOC_TITLE" =~ \n ]]
then
    bye "Cannot retrieve version from TOC file"
fi
if [ -z "$VERSION_CHANGELOG" ] || [[ "$VERSION_CHANGELOG" =~ \n ]]
then
    bye "Cannot retrieve version from ChangeLog file"
fi
if [ "$VERSION_TOC_VERSION" != "$VERSION_TOC_TITLE" ] || [ "$VERSION_TOC_VERSION" != "$VERSION_CHANGELOG" ]
then
    bye "Versions do not match: $VERSION_TOC_VERSION (toc, version) vs. $VERSION_TOC_TITLE (toc, title) vs. $VERSION_CHANGELOG (changelog)"
fi

# Release wrath and vanilla in a single package

echo -n "Creating release directory... "
rm -rf ./_release || bye "Cannot clean directory"
mkdir -p ./_release/$AddonName || bye "Cannot create directory"
echo

echo -n "Copying files... "
cp -R changelog.md LICENSE $AddonName.* src ./_release/$AddonName/ || bye "Cannot copy files"
cd ./_release || bye "Cannot cd to directory"
echo

echo -n "Updating TOC files... "
# To know the version of a specific game client, enter: /dump select(4, GetBuildInfo())
VANILLA_BUILD_VERSION=11505
WRATH_BUILD_VERSION=30403
CATA_BUILD_VERSION=40401
cp $AddonName/$AddonName.toc $AddonName/${AddonName}_Classic.toc
sed -i s/'^## Interface:.*'/"## Interface: $VANILLA_BUILD_VERSION"/ $AddonName/${AddonName}_Classic.toc || bye "Cannot update version of TOC file"
cp $AddonName/$AddonName.toc $AddonName/${AddonName}_Wrath.toc
sed -i s/'^## Interface:.*'/"## Interface: $WRATH_BUILD_VERSION"/ $AddonName/${AddonName}_Wrath.toc || bye "Cannot update version of TOC file"
cp $AddonName/$AddonName.toc $AddonName/${AddonName}_Cata.toc
sed -i s/'^## Interface:.*'/"## Interface: $CATA_BUILD_VERSION"/ $AddonName/${AddonName}_Cata.toc || bye "Cannot update version of TOC file"
rm $AddonName/$AddonName.toc || bye "Cannot remove generic TOC file"
echo

echo -n "Zipping directory... "
"$CWD"/zip -9 -r -q $AddonName-"$VERSION_TOC_VERSION".zip $AddonName || bye "Cannot zip directory"
echo

explorer . # || bye "Cannot open explorer to release directory"
