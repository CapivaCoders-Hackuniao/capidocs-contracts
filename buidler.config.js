usePlugin("@nomiclabs/buidler-waffle");
module.exports = {
  defaultNetwork: "buidlerevm",
  solc: {
    version: "0.7.0",
    optimizer: { enabled: true, runs: 100 },
  },
  paths: {
    tests: "./test",
    artifacts: "./build/contracts",
  },
  buidlerevm: {
    loggingEnabled: true,
  },
};
