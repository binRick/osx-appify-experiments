#!/usr/bin/env bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export PATH=/usr/local/bin:$PATH:/usr/libexec
cd ../.
ARGS="$@"
SIC_SERVER=f29
CFG="$(pwd)/etc/alacritty.yml"
APP_NAME="${APP_NAME:-RedTerminal}"
REMOTE_SERVER=${REMOTE_SERVER:-APP_NAME}
APP_ICON="${APP_ICON:-$(pwd)/icons/terminal_icon.png}"
APP_EXEC="$(pwd)/bin/alacritty"
ARGS="${ARGS} --config-file $CFG -e command ssh $REMOTE_SERVER"
SSH_HOST="${SSH_HOST:-$REMOTE_SERVER}"
SSH_USER="${SSH_USER:-root}"
SSH_PORT="${SSH_PORT:-22}"
SSH_REMOTE_SHELL="${SSH_REMOTE_SHELL:-zsh}"
SSH_CONTROLMASTER="${SSH_CONTROLMASTER:-auto}"
SSH_LOGLEVEL="${SSH_LOGLEVEL:-quiet}"
SSH_CONFIG=ssh_config
SSH_LOCAL_FWD="-L12345:127.0.0.1:12345 -D 13328"
SetEnv="ITERM_SESSION_ID=123"
RemoteCommand="/bin/$SSH_REMOTE_SHELL -il"
TERMINAL_SSH_OPTS="-C -Att -oStrictHostKeyChecking=no -x -4 -oPort=$SSH_PORT -oLogLevel=$SSH_LOGLEVEL -oUser=$SSH_USER -oControlMaster=$SSH_CONTROLMASTER -oBatchMode=yes -oClearAllForwardings=yes -oCheckHostIP=no -oConnectTimeout=3 -oConnectionAttempts=1 -oControlPersist=yes -oExitOnForwardFailure=yes -oKbdInteractiveAuthentication=no -oSetEnv=\"$SetEnv\" -oRemoteCommand=\"$RemoteCommand\" -oTCPKeepAlive=yes -F \"\$APP_DIR/$SSH_CONFIG\" $SSH_LOCAL_FWD"

remote_img=/tmp/$(date +%s)-$(basename $APP_ICON)
oremote_img=o-$remote_img

rsync_cmd="rsync $APP_ICON $SIC_SERVER:$remote_img"
sic_cmd="sic -i $remote_img -o $oremote_img --draw-text \"$APP_NAME\" \"coord(150, 75)\" \"rgba(255, 255, 0, 255)\" \"size(70)\" \"font('/usr/share/fonts/dejavu-sans-mono-fonts/DejaVuSansMono-Bold.ttf')\" && file $oremote_img"
sic_cmd="echo $(echo -e "$sic_cmd"|base64 -w0)"
sic_cmd="ssh -Att -q -oLogLevel=error $SIC_SERVER '$sic_cmd|base64 -d|bash'"
eval $rsync_cmd
eval $sic_cmd
app_icon=$(mktemp).png
rsync $SIC_SERVER:$oremote_img $app_icon

[[ -d apps/$REMOTE_SERVER.app ]] && rm -rf apps/$REMOTE_SERVER.app
[[ -d apps/$APP_NAME.app ]] && rm -rf apps/$APP_NAME.app

CONFIG_FILE=config.yaml

launch_cmd="./${APP_NAME}_terminal --config-file \"\$APP_DIR/$CONFIG_FILE\" -e ssh $TERMINAL_SSH_OPTS $REMOTE_SERVER"

echo -e "#!/usr/bin/env bash\nset -e\ncd \$( cd \"\$( dirname \"\${BASH_SOURCE[0]}\" )\" && pwd )\nexport APP_DIR=\"\$(pwd)\"\n$launch_cmd" > $APP_NAME.sh
chmod +x $APP_NAME.sh

APP_EXEC=$APP_NAME.sh
cmd="appify -name $APP_NAME -icon $app_icon $APP_EXEC"
2>&1 echo -e "$cmd"
eval $cmd
mv $APP_NAME.app apps/.
CFBundleIdentifier="$REMOTE_SERVER Terminal"
CFBundleGetInfoString="$REMOTE_SERVER Terminal"
CFBundleName="$REMOTE_HOSTNAME Terminal"
CFBundleExecutable="$REMOTE_HOSTNAME Terminal.app"
PLIST_FILE=./apps/$APP_NAME.app/Contents/Info.plist
cp bin/alacritty apps/$APP_NAME.app/Contents/MacOS/${APP_NAME}_terminal
cp etc/alacritty.yml apps/$APP_NAME.app/Contents/MacOS/$CONFIG_FILE
cp ~/.ssh/config apps/$APP_NAME.app/Contents/MacOS/$SSH_CONFIG
mv "apps/$APP_NAME.app/Contents/MacOS/$APP_NAME.app" "apps/$APP_NAME.app/Contents/MacOS/$CFBundleExecutable"

PlistBuddy -c "Set CFBundleIdentifier $CFBundleIdentifier" $PLIST_FILE
PlistBuddy -c "Set CFBundleGetInfoString $CFBundleGetInfoString" $PLIST_FILE
PlistBuddy -c "Set CFBundleName $CFBundleName" $PLIST_FILE
PlistBuddy -c "Set CFBundleExecutable '$CFBundleExecutable'" $PLIST_FILE
PlistBuddy -c "Print CFBundleName" $PLIST_FILE
PlistBuddy -c "Print CFBundleExecutable" $PLIST_FILE
PlistBuddy -c "Print CFBundleIdentifier" $PLIST_FILE
PlistBuddy -c "Print CFBundleGetInfoString" $PLIST_FILE
PlistBuddy -c "Print CFBundleExecutable" $PLIST_FILE
bat $PLIST_FILE
unlink $APP_NAME.sh

#mv apps/$APP_NAME.app "apps/$CFBundleExecutable.app"

