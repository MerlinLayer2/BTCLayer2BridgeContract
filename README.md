
```shell
yarn install
npm run compile
npm run deploy

npm run verify
```

# Upgrade steps
1. update contract code
2. change PRIVATE_KEY in .env to owner private key
3. run on your needs:
```shell
npm run upgrade-bridge
```
```shell
npm run upgrade-bridge-erc20
```
```shell
npm run upgrade-bridge-erc721
```
