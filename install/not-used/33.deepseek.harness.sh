#curl -fsSL https://deb.nodesource.com/setup_26.x | sudo -E bash -
#sudo apt install nodejs -y

#npx @deepseek-ai/dsh web --port 9090

sudo npm install -g pnpm

cd $RUST_AGENT_INFRA_DEV_TOOLS
git clone https://github.com/deepseek-ai/deepseek-harness.git
cd deepseek-harness
pnpm install
pnpm run build

#pnpm dsh web





