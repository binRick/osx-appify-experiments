#!/usr/bin/env bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ../.
ARGS="$@"
SIC_SERVER=f29
CFG="$(pwd)/etc/alacritty.yml"
APP_NAME="${APP_NAME:-RedTerminal}"
REMOTE_SERVER=$APP_NAME
APP_ICON="${APP_ICON:-$(pwd)/icons/terminal_icon.png}"
APP_EXEC="$(pwd)/bin/alacritty"
ARGS="${ARGS} --config-file $CFG -e ssh $REMOTE_SERVER"

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

cmd="appify -name $APP_NAME -icon $app_icon $APP_EXEC"
2>&1 echo -e "$cmd"
eval $cmd

[[ -d apps/$APP_NAME.app ]] && rm -rf apps/$APP_NAME.app
mv $APP_NAME.app apps/.

launch_cmd="open -n -a $APP_NAME.app --args -e ssh $REMOTE_SERVER"

echo -e "#!/usr/bin/env bash\n$launch_cmd" >> $APP_NAME.sh

chmod +x $APP_NAME.sh
