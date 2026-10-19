mkdir -p $RUST_AGENT_INFRA_DEV_TOOLS/okf

cd $RUST_AGENT_INFRA_DEV_TOOLS/okf

echo "https://www.mindstudio.ai/blog/what-is-open-knowledge-format-okf-google-llm-wiki-standard" >> LINKS_TO_READ.txt
echo "https://cloud.google.com/blog/products/data-analytics/how-the-open-knowledge-format-can-improve-data-sharing" >> LINKS_TO_READ.txt
echo "https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf" >> LINKS_TO_READ.txt
echo "https://github.com/pumblus/okf-harness" >> LINKS_TO_READ.txt



curl -fsSL https://okf-harness.dev/install.sh | sh

cat LINKS_TO_READ.txt





