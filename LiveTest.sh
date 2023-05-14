RPC=http://localhost:9545
KEY=0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6
CONTRACT="./src/concrete/LiveTest.sol:LiveTest"
echo "Deploying $CONTRACT to $RPC"
ADDR=$(forge create $CONTRACT --rpc-url $RPC --private-key $KEY --json | jq -r '.deployedTo')
echo "Deployed to $ADDR"
echo "Calling test() on $ADDR"
RECEIPT=$(cast send $ADDR "test()" --rpc-url $RPC --private-key $KEY --json)
STATUS=$(echo $RECEIPT | jq -r '.status')

echo ""
echo $RECEIPT | jq -r '.'
echo ""

if [ "$STATUS" == "0x1" ]; then
  echo "[ Test PASSED ]"
  exit 0
else
  echo "[ Test FAILED ]"
  exit 1
fi
