## KILO CODE VERION IS : 7.4.20
#
#

sudo apt install wl-clipboard # you need to install this pkg for clipboard functionality of kilo-code cli
# this is for wayland, below is for xorg
sudo apt install xclip


mkdir -p $RUST_AGENT_INFRA_DEV_TOOLS/kilo-code

cd $RUST_AGENT_INFRA_DEV_TOOLS/kilo-code

#curl -fsSL https://kilo.ai/cli/install | bash
#curl -fsSL https://kilo.ai/cli/install 


wget https://kilo.ai/cli/install 
chmod +x install
./install


grep "http://localhost:8787/v1" $HOME/.config/kilo/kilo.jsonc > /dev/null
if [ $? = 0 ]
then
    cp $HOME/.config/kilo/kilo.jsonc $HOME/.config/kilo/kilo.jsonc.org
    rm -f $HOME/.config/kilo/kilo.jsonc
    cp $RUST_AGENT_INFRA_DIR/install/23.kilo.jsonc $HOME/.config/kilo/kilo.jsonc
    echo " Change the apiKey in file $HOME/.config/kilo/kio.jsonc file, Get API KEY from the new-api admin web intraface (http://localhost:3000/keys) , click on the copy icon near the Api Key of API_KEY_0 line.  Auth = Bearer, <paste the api key you copied from new-api>,  Save"
else
    echo " $HOME/.config/kilo/kio.jsonc file contains http://localhost:3000/keys, maybe it would be good idea to check the apiKey in that file :)"
fi

echo "Print Any Key"
read 

echo "
KILO CODE command line tool is installed.

If you also want to install kilo-code extyension of vscode, please follow these instructions :

1. Start VSCode : cd $RUST_AGENT_INFRA_DEV_TOOLS/dev-tools/VSCode-linux-x64; ./code.sh

2. Press Ctrl-Shift-x  

3. Write 'kilo code' into the filtering text field which is found on the left - top of the VSCode.

4. Click install on the extension which has 'Kilo Code : AI Coding agent that generates code from natural language ......'

5. The Kilo Code icon will appear on the left bar of the VSCode.
"



echo "Print Any Key"
read 




 


