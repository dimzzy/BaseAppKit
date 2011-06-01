#!/bin/bash

function failed()
{
  echo "Failed $*: $@" >&2
  exit 1
}

export OUTPUT=$WORKSPACE/output
rm -rf $OUTPUT
mkdir -p $OUTPUT

PROFILE_HOME=~/Library/MobileDevice/Provisioning\ Profiles/
[ -d "$PROFILE_HOME" ] || mkdir -p "$PROFILE_HOME"

KEYCHAIN=~/Library/Keychains/login.keychain
security unlock -p `cat ~/.build_password`

MARKETING_VERSION=`agvtool what-marketing-version -terse1`;
cp $WORKSPACE/BADemo/Info.plist $WORKSPACE/BADemo/Info.plist.orig


for CONFIG in $CONFIGS; do

  if [ "$CONFIG" == "AdHoc" ]
  then
    VERSION="$MARKETING_VERSION.build$BUILD_NUMBER"
    agvtool new-version -all $VERSION
  else
    VERSION="$MARKETING_VERSION"
    cp $WORKSPACE/BADemo/Info.plist.orig $WORKSPACE/BADemo/Info.plist
  fi

  xcodebuild -target BADemo -configuration $CONFIG -sdk iphoneos4.3 build || failed build;

  PROVISION="$WORKSPACE/autobuild/BADemo_$CONFIG.mobileprovision"

  APP_OUT="$OUTPUT/BADemo_$CONFIG.ipa"
  SYMBOLS_OUT="$OUTPUT/BADemo_$CONFIG.dSYM"
  PROVISION_OUT="$OUTPUT/BADemo_$CONFIG.mobileprovision"

(
  cd build/$CONFIG-iphoneos || failed "no build output";
  rm -rf Payload
  rm -f *.ipa
  mkdir Payload
  cp -Rp *.app Payload/

#  if [ "$CONFIG" == "AdHoc" ]
#  then
#    cp -f $WORKSPACE/BADemo/Icon_512x512.png Payload/iTunesArtwork
#  fi

  zip -r $APP_OUT Payload
  cp -Rp *.dSYM $SYMBOLS_OUT
  cp $PROVISION $PROVISION_OUT

  curl http://testflightapp.com/api/builds.json \
-F file=@$APP_OUT \
-F api_token='$TF_API_TOKEN' \
-F team_token='$TF_TEAM_TOKEN' \
-F notes='Auto Build' \
-F notify=True \
-F distribution_lists='BADemo'\

)

done
