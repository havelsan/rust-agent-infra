

if [ -f $RUST_AGENT_INFRA_DEV_TOOLS/opencode/*opencode* ]
then
	echo "You already have  $RUST_AGENT_INFRA_DEV_TOOLS/opencode/*opencode* "
	exit 0
fi

mkdir -p $RUST_AGENT_INFRA_DEV_TOOLS/opencode

cd $RUST_AGENT_INFRA_DEV_TOOLS/opencode

wget https://opencode.ai/install
bash ./install


echo "
KILO CODE command line tool is installed.

If you also want to install kilo-code extyension of vscode, please follow these instructions :

1. Start VSCode : cd $RUST_AGENT_INFRA_DEV_TOOLS/dev-tools/VSCode-linux-x64; ./code.sh

2. Press Ctrl-Shift-x  

3. Write 'opencode gui' into the filtering text field which is found on the left - top of the VSCode.

4. Click install on the extension which has 'Open Code GUI : Open Code AI coding agent ......'

5. The Open Code icon will appear on the left bar of the VSCode.
"





