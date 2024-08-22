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
  const AAVE_POOL_PROVIDER_BASE_SEPOLIA = "0xd449FeD49d9C443688d6816fE6872F21402e41de";

  const Thrive = await deploy("Thrive", {
    from: deployer,
    args: [USDC_ADDRESS],
    log: true,
    // deterministicDeployment: false,
    autoMine: true,
  });
  const ThrivePiggy = await deploy("ThrivePiggy", {
    from: deployer,
    args: [AAVE_POOL_PROVIDER_BASE_SEPOLIA, USDC_ADDRESS, deployer], // Thrive.address
    log: true,
    // deterministicDeployment: false,
    autoMine: true,
  });

  console.log("ThrivePiggy::", ThrivePiggy.address);
};

func.tags = ["Thrive", "Th"];

export default func;
