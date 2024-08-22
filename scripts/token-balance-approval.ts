// import { HardhatRuntimeEnvironment } from "hardhat/types";
import { ethers, getNamedAccounts } from "hardhat";
const func = async function () {
  const { deployer } = await getNamedAccounts();

  const thrivePiggy = await ethers.getContract("ThrivePiggy", deployer);
  const USDC_ADDRESS = "0x036CbD53842c5426634e7929541eC2318f3dCF7e";
  console.log("this is deployer", deployer);
  //checks
  console.log("verify protocol contracts", thrivePiggy.address);

  const usdcContract = await ethers.getContractAt(ERC20_ABI, USDC_ADDRESS);

  const deployerUSDCBalance = await usdcContract.balanceOf(deployer);
  console.log("Deployer USDC deployerUSDCBalance balance:", ethers.utils.formatUnits(deployerUSDCBalance, 6));

  const thrivePiggyUSDCBalance = await usdcContract.balanceOf(thrivePiggy.address);
  console.log("Deployer USDC thrive piggy balance:", ethers.utils.formatUnits(thrivePiggyUSDCBalance, 6));

  const deployerUSDCAllowance = await usdcContract.allowance(deployer, thrivePiggy.address);
  console.log("Deployer USDC allowance for ThrivePiggy:", ethers.utils.formatUnits(deployerUSDCAllowance, 6));

  console.log("Approving ThrivePiggy contract to spend USDC...");
  //   const approvalAmount = ethers.utils.parseUnits("1000", 6);

  //   try {
  //     const approveTx = await usdcContract.approve(thrivePiggy.address, approvalAmount);
  //     await approveTx.wait();
  //     console.log("Approval successful");
  //   } catch (error) {
  //     console.error("Error during approval:", error);
  //     return;
  //   }
  //   const transferAmount = ethers.utils.parseUnits("5", 6);
  //   try {
  //     const approveTx = await usdcContract.transfer(thrivePiggy.address, transferAmount);
  //     await approveTx.wait();
  //     console.log("Transfer successful");
  //   } catch (error) {
  //     console.error("Error during approval:", error);
  //     return;
  //   }
};

func();

const ERC20_ABI = [
  {
    constant: true,
    inputs: [],
    name: "name",
    outputs: [{ name: "", type: "string" }],
    type: "function",
  },
  {
    constant: true,
    inputs: [],
    name: "symbol",
    outputs: [{ name: "", type: "string" }],
    type: "function",
  },
  {
    constant: true,
    inputs: [],
    name: "decimals",
    outputs: [{ name: "", type: "uint8" }],
    type: "function",
  },
  {
    constant: true,
    inputs: [],
    name: "totalSupply",
    outputs: [{ name: "", type: "uint256" }],
    type: "function",
  },
  {
    constant: true,
    inputs: [{ name: "_owner", type: "address" }],
    name: "balanceOf",
    outputs: [{ name: "balance", type: "uint256" }],
    type: "function",
  },
  {
    constant: false,
    inputs: [
      { name: "_to", type: "address" },
      { name: "_value", type: "uint256" },
    ],
    name: "transfer",
    outputs: [{ name: "", type: "bool" }],
    type: "function",
  },
  {
    constant: false,
    inputs: [
      { name: "_spender", type: "address" },
      { name: "_value", type: "uint256" },
    ],
    name: "approve",
    outputs: [{ name: "", type: "bool" }],
    type: "function",
  },
  {
    constant: true,
    inputs: [
      { name: "_owner", type: "address" },
      { name: "_spender", type: "address" },
    ],
    name: "allowance",
    outputs: [{ name: "", type: "uint256" }],
    type: "function",
  },
];
