import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";

const func: DeployFunction = async function ({
  getNamedAccounts,
  deployments,
}: // getChainId,
HardhatRuntimeEnvironment) {
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  const USDC_ADDRESS = "0x036CbD53842c5426634e7929541eC2318f3dCF7e";

  await deploy("Thrive", {
    from: deployer,
    args: [USDC_ADDRESS],
    log: true,
    // deterministicDeployment: false,
    autoMine: true,
  });
};

func.tags = ["Thrive", "Th"];

export default func;
