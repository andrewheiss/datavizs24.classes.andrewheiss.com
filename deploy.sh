REMOTE_HOST="ath-cloud"
REMOTE_DIR="~/sites/classes/datavizs24.classes/public"
REMOTE_DEST=$REMOTE_HOST:$REMOTE_DIR

echo "Uploading new changes to remote server..."
echo
rsync -crvP --delete _site/ $REMOTE_DEST
