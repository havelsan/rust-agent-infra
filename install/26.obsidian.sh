

if [ -f $RUST_AGENT_INFRA_DEV_TOOLS/obsidian/Obsidian*.AppImage ]
then
	echo "You already have  $RUST_AGENT_INFRA_DEV_TOOLS/obsidian/Obsidian*.AppImage "
	exit 0
fi

mkdir -p $RUST_AGENT_INFRA_DEV_TOOLS/obsidian

cd $RUST_AGENT_INFRA_DEV_TOOLS/obsidian

if [ ! -f $HOME/Downloads/Obsidian*.AppImage ]
then

    echo "Opening Download Page of Obsidian"
    echo "Click on the Donload button"
    echo " Re-run this script ($0) when the download is finished"
    firefox https://obsidian.md/download
fi


mv $HOME/Downloads/Obsidian*.AppImage .

chmod +x Obsidian*.AppImage

echo "./Obsidian-*.AppImage" > run.sh
chmod +x run.sh

echo "$RUST_AGENT_INFRA_DEV_TOOLS/obsidian/Obsidian*.AppImage is installed, you may run it"

