
cd $RUST_AGENT_INFRA_DEV_TOOLS/

wget https://storage.googleapis.com/antigravity-public/antigravity-hub/2.6.0-4603467860410368/linux-x64/Antigravity.tar.gz

tar -xvzf Antigravity.tar.gz

cd Antigravity-*

echo "./antigravity --no-sandbox" > antigravity.sh

chmod +x antigravity.sh












